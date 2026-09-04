with open("src/client/GuestRenderer.luau", "r", encoding="utf-8") as f:
    code = f.read()

code = code.replace("local torso = makePart", "makePart")
code = code.replace("local shirt = makePart", "makePart")
code = code.replace("local tie = makePart", "makePart")
code = code.replace("local belt = makePart", "makePart")
code = code.replace("local buckle = makePart", "makePart")
code = code.replace("local legL = makePart", "makePart")
code = code.replace("local legR = makePart", "makePart")
code = code.replace("local shoeL = makePart", "makePart")
code = code.replace("local shoeR = makePart", "makePart")
code = code.replace("local armL = makePart", "makePart")
code = code.replace("local armR = makePart", "makePart")
code = code.replace("local void = makePart", "makePart")
code = code.replace("local isHollow = false\n", "")
code = code.replace("local Players = game:GetService(\"Players\")\n", "")
code = code.replace("local IRIS_PALETTES = {", "-- local IRIS_PALETTES = {")
code = code.replace("table.insert(activeEyelids, faceDecal)", "table.insert(activeEyelids, { face = faceDecal })")
code = code.replace("face.Parent", "face.Parent and face.Parent.Parent")
code = code.replace("for _, face in ipairs(activeEyelids) do\n							if face.Parent and face.Parent.Parent then", "for _, lid in ipairs(activeEyelids) do\n							local face = lid.face\n							if face and face.Parent then")

with open("src/client/GuestRenderer.luau", "w", encoding="utf-8") as f:
    f.write(code)
