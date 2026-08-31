"""
Prepare a generated mesh (Tripo3D, Meshy, Rodin, Hunyuan, Sketchfab) for Roblox.

tools/blender_export.py already handles the three FBX export traps, but it only
*reports* the triangle count -- it will not reduce it. Generators routinely emit
100k+ triangle meshes, which Roblox refuses outright, so something has to sit in
front of it. That is this script.

    import  ->  apply transforms  ->  decimate to budget  ->  UV if missing  ->  export

Budgets and the export itself come from blender_export, so there is exactly one
definition of each number and one exporter.

Headless, the whole way through:

    blender --background --python tools/mesh_prep.py -- --in downloads/statue.glb --export

Or prepare only, and look at it in Blender before exporting:

    blender --python tools/mesh_prep.py -- --in downloads/statue.glb

The input file is never modified. Everything happens in the Blender scene.
"""

import argparse
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from blender_export import (  # noqa: E402
    TRIANGLE_BUDGET,
    TRIANGLE_HARD_CAP,
    export_one,
    triangle_count,
)

# Roblox downsamples anything larger, so a bigger texture costs upload time and
# buys nothing.
MAX_TEXTURE_PX = 1024


def parse_args() -> argparse.Namespace:
    argv = sys.argv
    argv = argv[argv.index("--") + 1 :] if "--" in argv else []
    p = argparse.ArgumentParser(prog="mesh_prep")
    p.add_argument("--in", dest="src", required=True, help="generated .glb/.gltf/.fbx/.obj")
    p.add_argument(
        "--budget",
        type=int,
        default=TRIANGLE_BUDGET,
        help=f"triangle target after decimation (default {TRIANGLE_BUDGET:,})",
    )
    p.add_argument("--export", action="store_true", help="also write the Roblox-ready .fbx")
    p.add_argument("--out", default="assets", help="output directory when --export is given")
    p.add_argument(
        "--keep-scene",
        action="store_true",
        help="do not clear the scene first (default clears, so counts are unambiguous)",
    )
    return p.parse_args(argv)


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def import_any(path: Path) -> list:
    """Import by extension and return the meshes it produced."""
    before = set(bpy.context.scene.objects)
    ext = path.suffix.lower()

    if ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=str(path))
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=str(path))
    elif ext == ".obj":
        # Blender 4.x renamed the OBJ importer; 3.x still has the old one.
        if hasattr(bpy.ops.wm, "obj_import"):
            bpy.ops.wm.obj_import(filepath=str(path))
        else:
            bpy.ops.import_scene.obj(filepath=str(path))
    else:
        raise SystemExit(f"unsupported input {ext!r} -- use .glb, .gltf, .fbx or .obj")

    return [o for o in set(bpy.context.scene.objects) - before if o.type == "MESH"]


def decimate(obj, budget: int) -> tuple[int, int]:
    """Collapse-decimate down to budget. Returns (before, after)."""
    before = triangle_count(obj)
    if before <= budget:
        return before, before

    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

    mod = obj.modifiers.new(name="RobloxBudget", type="DECIMATE")
    mod.decimate_type = "COLLAPSE"
    mod.ratio = budget / before
    bpy.ops.object.modifier_apply(modifier=mod.name)

    return before, triangle_count(obj)


def ensure_uvs(obj) -> bool:
    """Smart-project UVs only when the generator did not supply any."""
    if obj.data.uv_layers:
        return False
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=1.15)
    bpy.ops.object.mode_set(mode="OBJECT")
    return True


def oversized_textures() -> list[str]:
    out = []
    for img in bpy.data.images:
        w, h = img.size
        if max(w, h) > MAX_TEXTURE_PX:
            out.append(f"{img.name} {w}x{h}")
    return out


def main() -> None:
    args = parse_args()
    src = Path(args.src).expanduser().resolve()
    if not src.is_file():
        raise SystemExit(f"no such file: {src}")

    if args.budget > TRIANGLE_HARD_CAP:
        raise SystemExit(
            f"--budget {args.budget:,} is above Roblox's {TRIANGLE_HARD_CAP:,} hard cap"
        )

    if not args.keep_scene:
        clear_scene()

    meshes = import_any(src)
    if not meshes:
        raise SystemExit(f"{src.name} imported no meshes")

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    exported = 0
    for obj in meshes:
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        # Generators love arbitrary object scale. Bake it before measuring.
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

        before, after = decimate(obj, args.budget)
        unwrapped = ensure_uvs(obj)

        line = f"{obj.name:<28} {before:>8,} -> {after:>7,} tris"
        if unwrapped:
            line += "  (smart-projected UVs)"
        print(line)

        if args.export:
            ok, note = export_one(obj, out_dir)
            print(f"    {'exported' if ok else 'refused '}  {note}")
            exported += 1 if ok else 0

    for warning in oversized_textures():
        print(f"WARNING texture over {MAX_TEXTURE_PX}px, Roblox will downsample: {warning}")

    if args.export:
        print(f"\n{exported}/{len(meshes)} exported to {out_dir.resolve()}")
    else:
        print(f"\n{len(meshes)} mesh(es) prepared. Export with:")
        print(f"    blender --background --python tools/blender_export.py -- --all --out {args.out}")


if __name__ == "__main__":
    main()
