--!strict
-- The shop. Opens between shifts, sells the upgrade tree.
--
-- The server owns the wallet, the prices and the prerequisites. The client sends
-- an id string and nothing else. It cannot name its own price, cannot buy what
-- it cannot afford, and cannot skip a prerequisite, because it is never asked
-- about any of those -- the server looks them up itself.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))

local Shift = require(script.Parent:WaitForChild("Shift"))
local State = require(script.Parent:WaitForChild("State"))

local requestPurchase = Remotes.get("RequestPurchase")
local shopState = Remotes.get("ShopState")
local startShift = Remotes.get("StartShift")

-- A client can fire a remote as fast as it likes. Nothing here is expensive, but
-- unbounded remote handling is how a single player stalls a server.
local MIN_SECONDS_BETWEEN_CALLS = 0.15
local lastCall: { [Player]: number } = {}

local Shop = {}

local function throttled(player: Player): boolean
	local now = os.clock()
	local last = lastCall[player]
	if last and now - last < MIN_SECONDS_BETWEEN_CALLS then
		return true
	end
	lastCall[player] = now
	return false
end

-- Build the full shop view for one player. Availability is computed here so the
-- client never has to work out why a button is dead -- it is told.
local function push(player: Player)
	local p = State.get(player)
	if not p then
		return
	end

	local items = {}
	for _, u in Upgrades.list do
		local buyable, reason = Upgrades.canBuy(u, p.owned, p.takings)
		table.insert(items, {
			id = u.id,
			name = u.name,
			blurb = u.blurb,
			cost = u.cost,
			owned = p.owned[u.id] == true,
			buyable = buyable,
			reason = reason,
		})
	end

	local stats = Upgrades.stats(p.owned)
	shopState:FireClient(player, {
		takings = p.takings,
		nightsWorked = p.nightsWorked,
		items = items,
		guestsPerShift = stats.guestsPerShift,
		tellChance = stats.tellChance,
		payout = stats.payout,
		lastShiftSurvived = p.lastShiftSurvived,
	})
end

Shop.push = push

local function buy(player: Player, id: string)
	local p = State.get(player)
	if not p then
		return
	end

	-- Refuse to sell mid-shift. The shop is a between-nights space; allowing a
	-- purchase while a guest is at the desk would let a player buy their way out
	-- of a call they had already been shown.
	if p.shiftActive then
		return
	end

	local upgrade = Upgrades.byId(id)
	if not upgrade then
		return -- unknown id: a stale client, or a crafted one
	end

	local buyable = Upgrades.canBuy(upgrade, p.owned, p.takings)
	if not buyable then
		push(player) -- resync the client; its view was wrong
		return
	end

	p.takings -= upgrade.cost
	p.owned[upgrade.id] = true
	push(player)
	-- A tool bought in the shop has to be usable when the next shift starts, and
	-- the client only learns what is installed from this remote.
	Shift.pushLoadout(player)
end

function Shop.bind()
	requestPurchase.OnServerEvent:Connect(function(player: Player, id: unknown)
		if typeof(id) ~= "string" or #id > 64 then
			return
		end
		if throttled(player) then
			return
		end
		buy(player, id)
	end)

	startShift.OnServerEvent:Connect(function(player: Player)
		if throttled(player) then
			return
		end
		local p = State.get(player)
		if not p or p.shiftActive then
			return -- already working a shift
		end
		Shift.start(player)
	end)
end

function Shop.forget(player: Player)
	lastCall[player] = nil
end

return Shop
