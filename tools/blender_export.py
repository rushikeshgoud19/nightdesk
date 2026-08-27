"""
Export selected Blender objects as Roblox-ready FBX.

Roblox has three import gotchas that bite everyone once. This script handles all
three so nobody has to remember them:

  1. Scale. Blender FBX lands 100x too large in Studio. Export scale 0.01 cancels it.
  2. Unapplied transforms. If object scale/rotation is not baked into mesh data
     before export, the model arrives skewed. This is the single most common cause
     of "why is my mesh weird".
  3. Triangle budget. Roblox rejects meshes over 21,000 triangles on single import,
     and roughly 10,000 through Asset Manager batch import. We target the lower
     number so an asset works through either path.

Run from Blender's Text Editor with objects selected, or headless:

    blender scene.blend --background --python tools/blender_export.py -- --out assets/

Nothing is destroyed: transforms are applied to a temporary duplicate, and the
originals are left exactly as you had them.
"""

import argparse
import sys
from pathlib import Path

import bpy

# Lower of Roblox's two limits, so exports work through single AND batch import.
TRIANGLE_BUDGET = 10_000
# Hard ceiling Roblox will refuse outright.
TRIANGLE_HARD_CAP = 21_000
# Cancels the 100x enlargement Roblox applies to Blender FBX.
ROBLOX_FBX_SCALE = 0.01


def parse_args() -> argparse.Namespace:
    argv = sys.argv
    argv = argv[argv.index("--") + 1:] if "--" in argv else []
    p = argparse.ArgumentParser(prog="blender_export")
    p.add_argument("--out", default="assets", help="output directory for .fbx files")
    p.add_argument(
        "--all",
        action="store_true",
        help="export every mesh in the scene instead of just the selection",
    )
    return p.parse_args(argv)


def triangle_count(obj: "bpy.types.Object") -> int:
    """Evaluated triangle count, i.e. after modifiers, which is what Roblox sees."""
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = obj.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh()
    try:
        mesh.calc_loop_triangles()
        return len(mesh.loop_triangles)
    finally:
        evaluated.to_mesh_clear()


def targets(export_all: bool) -> list:
    pool = bpy.context.scene.objects if export_all else bpy.context.selected_objects
    return [o for o in pool if o.type == "MESH"]


def export_one(obj, out_dir: Path) -> tuple[bool, str]:
    tris = triangle_count(obj)

    if tris > TRIANGLE_HARD_CAP:
        return False, f"{tris:,} triangles — over Roblox's {TRIANGLE_HARD_CAP:,} hard cap, refused"

    note = f"{tris:,} triangles"
    if tris > TRIANGLE_BUDGET:
        note += f" — over {TRIANGLE_BUDGET:,}, single import only (Asset Manager will reject)"

    # Work on a duplicate so applying transforms never touches the user's scene.
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.duplicate()
    dup = bpy.context.active_object

    try:
        # Gotcha 2: bake scale and rotation into the mesh data.
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

        path = out_dir / f"{obj.name}.fbx"
        bpy.ops.export_scene.fbx(
            filepath=str(path),
            use_selection=True,
            # Gotcha 1: cancel Roblox's 100x enlargement.
            global_scale=ROBLOX_FBX_SCALE,
            apply_unit_scale=True,
            apply_scale_options="FBX_SCALE_ALL",
            # Roblox is Y-up / -Z-forward.
            axis_forward="-Z",
            axis_up="Y",
            object_types={"MESH"},
            use_mesh_modifiers=True,
            mesh_smooth_type="FACE",
            add_leaf_bones=False,
            bake_anim=False,
            path_mode="COPY",
            embed_textures=False,
        )
    finally:
        bpy.ops.object.delete()

    return True, note


def main() -> None:
    args = parse_args()
    out_dir = Path(bpy.path.abspath(f"//{args.out}")) if args.out.startswith("//") else Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    meshes = targets(args.all)
    if not meshes:
        print("nothing to export — select at least one mesh, or pass --all")
        return

    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")

    ok = 0
    for obj in meshes:
        exported, note = export_one(obj, out_dir)
        mark = "OK  " if exported else "SKIP"
        print(f"{mark} {obj.name:<28} {note}")
        ok += 1 if exported else 0

    print(f"\n{ok}/{len(meshes)} exported to {out_dir.resolve()}")
    print("Import in Studio: Avatar tab -> 3D Importer, or drag the .fbx into the viewport.")
    print(f"Keep textures at 1024x1024 or smaller; Roblox downsamples anything larger.")


if __name__ == "__main__":
    main()
