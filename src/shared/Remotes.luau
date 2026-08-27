--!strict
-- Single place where every RemoteEvent is declared, so the wire surface between
-- client and server is one file you can read in ten seconds.
--
-- The server creates them; the client waits for them. Nothing else in the codebase
-- calls Instance.new on a Remote.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	-- Server -> client: "here is who just walked up to the desk"
	"GuestArrived",
	-- Client -> server: "I say admit" / "I say refuse". Carries a boolean only.
	-- The client is never told whether the guest is an anomaly, so it cannot leak it.
	"Judge",
	-- Server -> client: "you were right/wrong, here is the new score"
	"ShiftUpdate",
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
