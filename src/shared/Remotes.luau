--!strict
-- Single place where every RemoteEvent is declared, so the wire surface between
-- client and server is one file you can read in ten seconds.
--
-- The server creates them; the client waits for them. Nothing else in the codebase
-- calls Instance.new on a Remote.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	-- Server -> client: "here is who just walked up to the desk". Carries the
	-- tell only when the player's upgrades have earned it; the server decides.
	"GuestArrived",
	-- Client -> server: "I say admit" / "I say refuse". Carries a boolean only.
	"Judge",
	-- Server -> client: "you were right/wrong, here is the running total"
	"ShiftUpdate",
	-- Server -> client: "the night is over, here is the summary" -- opens the shop
	"ShiftEnded",
	-- Client -> server: "I want to buy this upgrade". Carries an id string only.
	-- The server owns the price, the prerequisites, and the wallet.
	"RequestPurchase",
	-- Server -> client: full shop state -- owned set, takings, per-item availability
	"ShopState",
	-- Client -> server: "close the shop, start the next shift"
	"StartShift",
}

local Remotes = {}

local folder: Folder

if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("Remotes") :: Folder
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end

	for _, name in NAMES do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function Remotes.get(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
