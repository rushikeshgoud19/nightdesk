with open("src/client/GuestRenderer.luau", "r", encoding="utf-8") as f:
    code = f.read()

target = """	local hair = Instance.new("MeshPart")
	hair.Name = "Hair"
	hair.MeshId = hairMeshId
	hair.Size = Vector3.new(1.4, 0.8, 1.4)
	hair.CFrame = head.CFrame * CFrame.new(0, (headScaleY/2) + 0.1, 0)
	hair.Color = hairColor
	Materials.applySurface(hair, S.Hair)
	hair.Anchored = true
	hair.CanCollide = false
	hair.Parent = model"""

replacement = """	local hair = Instance.new("Part")
	hair.Name = "Hair"
	hair.Size = Vector3.new(1.4, 0.8, 1.4)
	hair.CFrame = head.CFrame * CFrame.new(0, (headScaleY/2) + 0.1, 0)
	hair.Color = hairColor
	Materials.applySurface(hair, S.Hair)
	hair.Anchored = true
	hair.CanCollide = false
	hair.Transparency = 1 -- Hide the block itself, show the mesh
	
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = hairMeshId
	mesh.Scale = Vector3.new(1.4, 0.8, 1.4)
	mesh.TextureId = ""
	mesh.VertexColor = Vector3.new(hairColor.R, hairColor.G, hairColor.B)
	mesh.Parent = hair
	
	hair.Parent = model"""

code = code.replace(target, replacement)

with open("src/client/GuestRenderer.luau", "w", encoding="utf-8") as f:
    f.write(code)
