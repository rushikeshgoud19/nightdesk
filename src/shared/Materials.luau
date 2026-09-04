--!strict
-- Material authority for nightdesk.
--
-- The MaterialVariants themselves are declared in default.project.json under
-- MaterialService and reach the place through Rojo. They are deliberately NOT
-- created at runtime: MaterialVariant.BaseMaterial carries Plugin security, so a
-- game Script that writes it raises "lacking capability Plugin" and takes down
-- whatever called it. This module only names them, and pairs each with the stock
-- material a part must be set to before the variant will apply.

local Materials = {}

-- A surface is a stock material plus the variant layered over it. Variant is nil
-- where the stock material is already right and there is nothing to override.
export type Surface = {
	Material: Enum.Material,
	Variant: string?,
}

local function surface(material: Enum.Material, variant: string?): Surface
	return table.freeze({ Material = material, Variant = variant })
end

-- The motel carries exactly one variant per stock material, so its lookup is
-- keyed by the material the caller already passes. The lobby architecture and the
-- desk props are the same set of surfaces and share it.
local MOTEL: { [Enum.Material]: string } = {
	[Enum.Material.SmoothPlastic] = "MotelSmoothPlastic",
	[Enum.Material.Metal] = "MotelMetal",
	[Enum.Material.Wood] = "MotelWood",
	[Enum.Material.Fabric] = "MotelFabric",
	[Enum.Material.Plaster] = "MotelPlaster",
	[Enum.Material.Leather] = "MotelLeather",
	[Enum.Material.WoodPlanks] = "MotelWoodPlanks",
	[Enum.Material.Concrete] = "MotelConcrete",
}

-- A guest is the opposite case: several distinct surfaces share one stock
-- material, so material alone cannot say which variant belongs on a part. Skin,
-- hair, an eyeball and a shoe sole are all SmoothPlastic and none of them should
-- look like the others. Callers name the surface instead.
--
-- Skin is the one that carries weight. colorless_skin is a desaturation, and a
-- colour shift that small has nothing to read against on a flat plastic surface
-- -- it needs pores and a broken specular to sit on.
Materials.guest = table.freeze({
	Skin = surface(Enum.Material.SmoothPlastic, "GuestSkin"),
	Hair = surface(Enum.Material.SmoothPlastic, "GuestHair"),
	Wool = surface(Enum.Material.Fabric, "GuestWool"),
	Suit = surface(Enum.Material.Fabric, "GuestSuit"),
	Shirt = surface(Enum.Material.Fabric, "GuestShirt"),
	Shoe = surface(Enum.Material.Leather, "GuestShoe"),
	WetSuit = surface(Enum.Material.Fabric, "GuestWetSuit"),
	Leather = surface(Enum.Material.Leather, "MotelLeather"),
	Brass = surface(Enum.Material.Metal, "MotelMetal"),
	-- Wet, hard and clean: eyeballs, teeth, bone, suit buttons, shoe soles.
	Gloss = surface(Enum.Material.SmoothPlastic),
	Wax = surface(Enum.Material.Ice),
	Glow = surface(Enum.Material.Neon),
	Vapor = surface(Enum.Material.Air),
})

-- Set a part to a named guest surface.
function Materials.applySurface(part: BasePart, s: Surface)
	part.Material = s.Material
	if s.Variant then
		part.MaterialVariant = s.Variant
	end
end

-- Set a part to a motel stock material, picking up its variant if one exists.
function Materials.applyMotel(part: BasePart, material: Enum.Material)
	part.Material = material
	local variant = MOTEL[material]
	if variant then
		part.MaterialVariant = variant
	end
end

return Materials
