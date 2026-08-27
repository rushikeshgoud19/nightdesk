"""
The lobby key rack — the shop's physical anchor.

Five hooks, one per room in the upgrade tree. Keys hang on the rooms you own, so
the board is a readable picture of your progress: an empty hook is something you
have not bought yet.

This script IS the source. The .blend is not committed — run this and you get the
identical mesh back. Text in git beats a binary you cannot diff.

    blender --background --python tools/models/keyrack.py
    # then export:
    blender --background --python tools/blender_export.py -- --out assets --all

Or run it inside a live Blender session (Text Editor, or over BlenderMCP), which
is how it was authored.

Proportions are deliberately NOT scale-accurate. A real key hook is about 8mm
across, which is invisible at Roblox viewing distance. Everything here is
exaggerated until it reads.
"""

import math

import bpy

NAME = "KeyRack"

W, H, T = 0.70, 0.44, 0.03  # board width, height, thickness (metres)
FRAME = 0.035  # frame border — chunky on purpose
HOOK_COUNT = 5  # one per room/floor upgrade in Upgrades.luau
KEYS_ON_HOOKS = 2  # rooms the player starts with


def clear() -> None:
    for obj in list(bpy.data.objects):
        if obj.name.startswith(NAME):
            bpy.data.objects.remove(obj, do_unlink=True)
    bpy.ops.object.select_all(action="DESELECT")


def box(parts: list, name: str, loc: tuple, dims: tuple):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = dims
    parts.append(obj)
    return obj


def build() -> "bpy.types.Object":
    clear()
    parts: list = []

    # Recessed backer panel.
    box(parts, f"{NAME}_panel", (0, 0, 0), (W - FRAME * 2, T * 0.5, H - FRAME * 2))

    # Frame rails, standing proud of the panel so it reads as a board, not a slab.
    box(parts, f"{NAME}_frTop", (0, -T * 0.25, H / 2 - FRAME / 2), (W, T, FRAME))
    box(parts, f"{NAME}_frBot", (0, -T * 0.25, -H / 2 + FRAME / 2), (W, T, FRAME))
    box(parts, f"{NAME}_frL", (-W / 2 + FRAME / 2, -T * 0.25, 0), (FRAME, T, H))
    box(parts, f"{NAME}_frR", (W / 2 - FRAME / 2, -T * 0.25, 0), (FRAME, T, H))

    for i in range(HOOK_COUNT):
        x = -0.24 + i * 0.12
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=10,
            radius=0.012,
            depth=0.075,
            location=(x, -T * 0.75, 0.055),
            rotation=(math.radians(90), 0, 0),
        )
        hook = bpy.context.active_object
        hook.name = f"{NAME}_hook{i}"
        parts.append(hook)

        # Upturn at the tip, so a key would actually stay on it.
        box(parts, f"{NAME}_tip{i}", (x, -T * 0.75 - 0.032, 0.070), (0.022, 0.016, 0.022))

        if i < KEYS_ON_HOOKS:
            box(parts, f"{NAME}_fob{i}", (x, -T * 0.75 - 0.012, -0.010), (0.042, 0.010, 0.085))
            box(parts, f"{NAME}_key{i}", (x, -T * 0.75 - 0.012, -0.075), (0.012, 0.006, 0.050))

    # Ledger shelf along the bottom.
    box(parts, f"{NAME}_shelf", (0, -0.055, -H / 2 + 0.03), (W - FRAME, 0.11, 0.022))

    # Roblox imports one MeshPart, not a hierarchy — join before export.
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()

    rack = bpy.context.active_object
    rack.name = NAME
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return rack


def main() -> None:
    rack = build()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    mesh = rack.evaluated_get(depsgraph).to_mesh()
    try:
        mesh.calc_loop_triangles()
        print(f"{NAME}: {len(mesh.loop_triangles)} triangles, {len(rack.data.vertices)} verts")
    finally:
        rack.evaluated_get(depsgraph).to_mesh_clear()


if __name__ == "__main__":
    main()
