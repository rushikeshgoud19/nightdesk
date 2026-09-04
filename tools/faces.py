"""Generates the guest face decals.

Every tier-1 face tell in the catalog is a claim about a measurable difference:
pupils 15% wider, the left eye 3mm lower, the whites 10% darker. Those numbers
are the design. Drawing the faces by hand would make them approximate, and an
approximate 4% difference is either invisible or obvious -- never 4%.

So all seven faces come out of one draw function, and each variant overrides
exactly one parameter of it. The delta is the anomaly, and it is exact by
construction.

    python tools/faces.py            writes PNGs to build/faces/

Reference: reference/guest-kit.png -- dark heavy eyes, a drawn mouth line, a
muted palette. The eyes keep a visible sclera because two of the tells are
statements about the whites and the pupils; solid black eyes cannot express
either.
"""

from __future__ import annotations

import math
import os
from dataclasses import dataclass, replace

from PIL import Image, ImageDraw, ImageFilter

SIZE = 512  # square decal, drawn once and applied to the head's front face

# A guest's face is roughly 200mm across in the fiction, and the drawn face
# occupies about 340px of the canvas. So one millimetre is about 1.7px, and the
# "3mm lower" tell is 5px. Keeping the conversion explicit is what stops the
# numbers drifting away from the tells the ledger promises.
PX_PER_MM = 340.0 / 200.0

INK = (26, 24, 24, 255)  # brow and mouth line
IRIS = (38, 32, 30, 255)
PUPIL = (12, 10, 10, 255)
SCLERA = (243, 240, 234, 255)


@dataclass(frozen=True)
class Face:
    """Every measurement the face is drawn from. Variants change one field."""

    eye_y: float = 206.0
    eye_dx: float = 74.0  # each eye's centre, offset from the midline
    sclera_w: float = 78.0
    sclera_h: float = 46.0
    iris_r: float = 23.0
    # The pupil is deliberately large. dilated_pupils is an honest 15% and 15% of
    # a small pupil is a sub-pixel change once the 512px decal is rendered onto a
    # 1.2-stud head across a counter -- the tell would be true and unplayable.
    # Widening the base pupil keeps the 15% exact and makes it perceivable.
    pupil_r: float = 15.5
    sclera: tuple = SCLERA

    # Real faces are not symmetrical. The base carries a small natural drop on
    # the left, which is what makes `perfect_symmetry` a tell at all -- a face
    # with none is the anomaly.
    left_eye_drop: float = 2.0

    mouth_y: float = 336.0
    mouth_w: float = 118.0
    mouth_curl: float = 0.0  # px the corners lift
    mouth_shift: float = 1.0  # natural off-centre

    brow_drop: float = 34.0
    brow_w: float = 88.0


def _ellipse(d: ImageDraw.ImageDraw, cx, cy, w, h, fill):
    d.ellipse([cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2], fill=fill)


def draw(f: Face) -> Image.Image:
    # Supersample, then downscale. Roblox renders these small and on an angle,
    # and aliased eyelines read as noise rather than as a face.
    ss = 2
    img = Image.new("RGBA", (SIZE * ss, SIZE * ss), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    mid = SIZE * ss / 2

    def s(v):
        return v * ss

    for side in (-1, 1):
        cx = mid + s(f.eye_dx) * side
        cy = s(f.eye_y) + (s(f.left_eye_drop) if side < 0 else 0)

        _ellipse(d, cx, cy, s(f.sclera_w), s(f.sclera_h), f.sclera)
        _ellipse(d, cx, cy, s(f.iris_r) * 2, s(f.iris_r) * 2, IRIS)
        _ellipse(d, cx, cy, s(f.pupil_r) * 2, s(f.pupil_r) * 2, PUPIL)

        # Upper lid, drawn over the eye. This is most of what makes the eyes
        # read as heavy and dark at conversation distance rather than as dots.
        d.chord(
            [
                cx - s(f.sclera_w) / 2,
                cy - s(f.sclera_h) / 2,
                cx + s(f.sclera_w) / 2,
                cy + s(f.sclera_h) / 2,
            ],
            180,
            360,
            fill=(0, 0, 0, 0),
        )
        d.arc(
            [
                cx - s(f.sclera_w) / 2,
                cy - s(f.sclera_h) / 2,
                cx + s(f.sclera_w) / 2,
                cy + s(f.sclera_h) / 2,
            ],
            180,
            360,
            fill=INK,
            width=int(s(3.5)),
        )

        # Brow
        by = cy - s(f.brow_drop)
        d.arc(
            [cx - s(f.brow_w) / 2, by - s(14), cx + s(f.brow_w) / 2, by + s(14)],
            195,
            345,
            fill=INK,
            width=int(s(5)),
        )

    # Mouth: a line with the corners lifted by mouth_curl. At curl 0 it is
    # closed and neutral; subtle_smile lifts it a few pixels and nothing else.
    mx = mid + s(f.mouth_shift)
    my = s(f.mouth_y)
    hw = s(f.mouth_w) / 2
    curl = s(f.mouth_curl)
    pts = []
    for i in range(41):
        t = i / 40.0
        x = mx - hw + hw * 2 * t
        # Parabola through the corners, flat when curl is 0.
        y = my - curl * (1 - (2 * t - 1) ** 2) * -1 - curl * ((2 * t - 1) ** 2)
        pts.append((x, y))
    d.line(pts, fill=INK, width=int(s(4.5)), joint="curve")

    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    return img.filter(ImageFilter.GaussianBlur(0.4))


BASE = Face()

VARIANTS: dict[str, Face] = {
    # The innocent face. Everything below is this, with one number moved.
    "face_base": BASE,
    # "pupils dilated exactly 15% wider"
    "face_dilated_pupils": replace(BASE, pupil_r=BASE.pupil_r * 1.15),
    # "left eye sits exactly 3 millimeters lower"
    "face_asymmetric": replace(BASE, left_eye_drop=BASE.left_eye_drop + 3.0 * PX_PER_MM),
    # "whites of their eyes are exactly 10% darker"
    "face_dark_sclera": replace(
        BASE, sclera=tuple(int(c * 0.90) for c in SCLERA[:3]) + (255,)
    ),
    # "lips curled into a very faint, unnatural half-smile"
    "face_subtle_smile": replace(BASE, mouth_curl=7.0),
    # "perfectly, mathematically symmetrical -- real faces are not"
    "face_perfect_symmetry": replace(BASE, left_eye_drop=0.0, mouth_shift=0.0),
}


def main():
    out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "build", "faces")
    os.makedirs(out, exist_ok=True)
    for name, face in VARIANTS.items():
        path = os.path.join(out, name + ".png")
        draw(face).save(path)
        delta = []
        for field in face.__dataclass_fields__:
            a, b = getattr(BASE, field), getattr(face, field)
            if a != b:
                delta.append(f"{field}: {a} -> {b}")
        print(f"{name:26s} {'  |  '.join(delta) if delta else '(the innocent face)'}")
    print(f"\nwrote {len(VARIANTS)} faces to {out}")


if __name__ == "__main__":
    main()
