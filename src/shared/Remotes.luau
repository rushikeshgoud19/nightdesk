--!strict
-- Single place where every RemoteEvent is declared, so the wire surface between
-- client and server is one file you can read in ten seconds.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"GuestArrived",
	"Judge",
	"ShiftUpdate",
	"SanityUpdate",
	"Loadout",
	"ShiftEnded",
	"RequestPurchase",
	"ShopState",
	"StartShift",
	"RingBell",
	"BellRang",
	"CallRoom",
	"PhoneResponse",
	"ToggleUV",
	"UVState",
	"Interrogate",
	"InterrogationResponse",
	-- Interactive Hallway & Office Remotes
	"BrewCoffee",
	"BuySoda",
	"ResetBreaker",
	"BreakerTripped",
	"BreakerRestored",
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
