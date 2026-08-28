"""
The motel front desk service bell — the iconic desk prop.

A small dome-and-plunger call bell that guests slap to get the clerk's attention.

This script IS the source. The .blend is not committed — run this and you get the
identical mesh back. Text in git beats a binary you cannot diff.

    blender --background --python tools/models/deskbell.py
    # then export:
    blender --background --python tools/blender_export.py -- --out assets --all

Or run it inside a live Blender session (Text Editor, or over BlenderMCP), which
is how it was authored.

Proportions are deliberately exaggerated for readability at game viewing distances:
- The base and dome are slightly wider and thicker than real life so the silhouette
  reads clearly from player camera height.
- The plunger button on top is chunky and stands proud of the dome so it is
  immediately recognizable as an interactive call bell.
- Target triangle count is under 1,000 triangles (single MeshPart).
"""

import math
import bmesh
import bpy

NAME = "DeskBell"

SEGMENTS = 20  # Clean circular silhouette


def clear() -> None:
    for obj in list(bpy.data.objects):
        if obj.name.startswith(NAME):
            bpy.data.objects.remove(obj, do_unlink=True)
    bpy.ops.object.select_all(action="DESELECT")


def create_lathed_mesh(name: str, profile_points: list[tuple[float, float]], segments: int = SEGMENTS) -> "bpy.types.Object":
    """
    Creates a manifold solid of revolution by revolving a 2D profile (radius, z) around the Z axis.
    profile_points: list of (radius, z) ordered sequentially.
    """
    bm = bmesh.new()

    rings = []
    for r, z in profile_points:
        ring = []
        if r <= 0.0001:
            v = bm.verts.new((0.0, 0.0, z))
            ring = [v] * segments
        else:
            for s in range(segments):
                angle = (2.0 * math.pi * s) / segments
                x = r * math.cos(angle)
                y = r * math.sin(angle)
                v = bm.verts.new((x, y, z))
                ring.append(v)
        rings.append(ring)

    for i in range(len(rings) - 1):
        r1 = rings[i]
        r2 = rings[i + 1]
        p1_r = profile_points[i][0]
        p2_r = profile_points[i + 1][0]

        if p1_r <= 0.0001 and p2_r > 0.0001:
            center_v = r1[0]
            for s in range(segments):
                s_next = (s + 1) % segments
                bm.faces.new((center_v, r2[s], r2[s_next]))
        elif p2_r <= 0.0001 and p1_r > 0.0001:
            center_v = r2[0]
            for s in range(segments):
                s_next = (s + 1) % segments
                bm.faces.new((center_v, r1[s_next], r1[s]))
        elif p1_r > 0.0001 and p2_r > 0.0001:
            for s in range(segments):
                s_next = (s + 1) % segments
                bm.faces.new((r1[s], r2[s], r2[s_next], r1[s_next]))

    # Ensure consistent outward normals
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    mesh_data = bpy.data.meshes.new(name)
    bm.to_mesh(mesh_data)
    bm.free()

    obj = bpy.data.objects.new(name, mesh_data)
    bpy.context.collection.objects.link(obj)
    return obj


def create_materials() -> tuple["bpy.types.Material", "bpy.types.Material"]:
    # Brass material for bell dome and button
    mat_brass = bpy.data.materials.get("DeskBell_Brass")
    if not mat_brass:
        mat_brass = bpy.data.materials.new("DeskBell_Brass")
        mat_brass.use_nodes = True
        bsdf = mat_brass.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = (0.85, 0.65, 0.15, 1.0)
            bsdf.inputs["Metallic"].default_value = 0.9
            bsdf.inputs["Roughness"].default_value = 0.25

    # Dark steel/iron material for base pedestal
    mat_base = bpy.data.materials.get("DeskBell_Base")
    if not mat_base:
        mat_base = bpy.data.materials.new("DeskBell_Base")
        mat_base.use_nodes = True
        bsdf = mat_base.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = (0.12, 0.12, 0.14, 1.0)
            bsdf.inputs["Metallic"].default_value = 0.8
            bsdf.inputs["Roughness"].default_value = 0.4

    return mat_brass, mat_base


def build() -> "bpy.types.Object":
    clear()
    parts: list = []

    # 1. Base Stand: Solid stepped cast pedestal with beveled lip (Z = 0.000 to 0.024)
    base_profile = [
        (0.000, 0.000),   # center bottom
        (0.078, 0.000),   # bottom outer diameter (15.6 cm across)
        (0.078, 0.006),   # bottom vertical lip
        (0.072, 0.010),   # chamfer inward
        (0.068, 0.012),   # step tier
        (0.026, 0.016),   # inner recess shoulder
        (0.026, 0.024),   # central support post
        (0.000, 0.024),   # post cap
    ]
    base_obj = create_lathed_mesh(f"{NAME}_Base", base_profile, segments=SEGMENTS)
    parts.append(base_obj)

    # 2. Bell Dome: Flared skirt curving gracefully to hemispherical dome (Z = 0.022 to 0.086)
    dome_profile = [
        (0.066, 0.022),   # flared bottom rim
        (0.063, 0.028),   # lower curve inward
        (0.058, 0.040),   # waist
        (0.052, 0.055),   # mid dome body
        (0.042, 0.070),   # upper dome shoulder
        (0.026, 0.082),   # crown curve
        (0.012, 0.086),   # collar apex
        (0.000, 0.086),   # top center
    ]
    dome_obj = create_lathed_mesh(f"{NAME}_Dome", dome_profile, segments=SEGMENTS)
    parts.append(dome_obj)

    # 3. Plunger Assembly: Central stem + top striker button (Z = 0.084 to 0.118)
    plunger_profile = [
        (0.000, 0.084),   # stem bottom center
        (0.006, 0.084),   # stem radius
        (0.006, 0.106),   # stem top
        (0.018, 0.108),   # plunger button underside
        (0.020, 0.113),   # button rim
        (0.017, 0.117),   # button top chamfer
        (0.000, 0.118),   # button apex
    ]
    plunger_obj = create_lathed_mesh(f"{NAME}_Plunger", plunger_profile, segments=SEGMENTS)
    parts.append(plunger_obj)

    # Assign materials
    mat_brass, mat_base = create_materials()
    base_obj.data.materials.append(mat_base)
    dome_obj.data.materials.append(mat_brass)
    plunger_obj.data.materials.append(mat_brass)

    # Join all components into single MeshPart for Roblox
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = dome_obj
    bpy.ops.object.join()

    bell = bpy.context.active_object
    bell.name = NAME

    # Smooth shading
    bpy.ops.object.shade_smooth()

    # Bake scale & rotation
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return bell


def main() -> None:
    bell = build()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    mesh = bell.evaluated_get(depsgraph).to_mesh()
    try:
        mesh.calc_loop_triangles()
        print(f"{NAME}: {len(mesh.loop_triangles)} triangles, {len(bell.data.vertices)} vertices")
    finally:
        bell.evaluated_get(depsgraph).to_mesh_clear()


if __name__ == "__main__":
    main()
