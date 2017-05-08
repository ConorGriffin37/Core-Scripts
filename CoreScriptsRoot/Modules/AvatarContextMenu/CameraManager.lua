--[[
	// FileName: CameraManager.lua
	// Written by: TheGamer101
	// Description: Module for managing the camera for the AvatarContextMenu.
]]

--- CONSTANTS:
local FOLLOW_FLIP_MODE_ENABLED = true
-- If FOLLOW_FLIP_MODE_ENABLED is disabled, FOLLOW_FRONT_VIEW toggles the front or back view.
local FOLLOW_FRONT_VIEW = false

local VIEWING_ANGLE_FRONT = 1
local VIEWING_ANGLE_FOLLOW = 2

-- The ammount in studs a player must move to be considered moving.
local PLAYER_MOVING_THRESHOLD = 2
-- If a Player does not move past the threshold in this many seconds, reset their start position to their current position.
local POSITION_RESET_TIMEOUT = 3
-- If a Player does not move within this time consider them to no longer be moving and
local FOLLOW_ANGLE_TIMEOUT = 5

local FLIP_CAMERA_ROTATE_TIME = 1.5

--- SERVICES
local Workspace = game:GetService("Workspace")
local PlayersService = game:GetService("Players")
local RunService = game:GetService("RunService")

-- VARIABLES
local LocalPlayer = PlayersService.LocalPlayer
while not LocalPlayer do
	PlayersService.PlayerAdded:wait()
	LocalPlayer = PlayersService.LocalPlayer
end

local CameraManager = {}
CameraManager.__index = CameraManager

function CameraManager:GetFollowEnabled()
	local followOption = LocalPlayer:FindFirstChild("FollowOption")
	if followOption and followOption.Value == 1 then
		return true
	end
	return false
end

function CameraManager:GetDesiredViewingAngle(newPlayerPosition)
	if (newPlayerPosition - self.LastPlayerPosition).magnitude > PLAYER_MOVING_THRESHOLD then
		self.LastCameraPlayerMoveTime = tick()
		self.LastPositionReset = tick()
		self.LastPlayerPosition = newPlayerPosition
	end
	if tick() - self.LastPositionReset > POSITION_RESET_TIMEOUT then
		self.LastPositionReset = tick()
		self.LastPlayerPosition = newPlayerPosition
	end
	if tick() - self.LastCameraPlayerMoveTime < FOLLOW_ANGLE_TIMEOUT then
		return VIEWING_ANGLE_FOLLOW
	end
	return VIEWING_ANGLE_FRONT
end

function CameraManager:TweenCameraPosition(currentCamera, selectedPlayerRootPart)
	local halfWayCFrame = CFrame.new((selectedPlayerRootPart.CFrame * CFrame.new(10, 0, 0)).p, selectedPlayerRootPart.Position)
	local startCFrame, endCFrame = nil, nil
	if self.DesiredViewingAngle == VIEWING_ANGLE_FRONT then
		startCFrame = self:GetCFrameForViewingAngle(VIEWING_ANGLE_FOLLOW, selectedPlayerRootPart)
		endCFrame = self:GetCFrameForViewingAngle(VIEWING_ANGLE_FRONT, selectedPlayerRootPart)
	elseif self.DesiredViewingAngle == VIEWING_ANGLE_FOLLOW then
		startCFrame = self:GetCFrameForViewingAngle(VIEWING_ANGLE_FRONT, selectedPlayerRootPart)
		endCFrame = self:GetCFrameForViewingAngle(VIEWING_ANGLE_FOLLOW, selectedPlayerRootPart)
	end

	if self.CameraTweenTimeIn > FLIP_CAMERA_ROTATE_TIME/2 then
		currentCamera.CFrame = halfWayCFrame:lerp(endCFrame, (self.CameraTweenTimeIn - FLIP_CAMERA_ROTATE_TIME/2)/(FLIP_CAMERA_ROTATE_TIME/2))
	else
		currentCamera.CFrame = startCFrame:lerp(halfWayCFrame, (self.CameraTweenTimeIn)/(FLIP_CAMERA_ROTATE_TIME/2))
	end
end

function CameraManager:GetSelectedPlayerRootPart()
	if self.SelectedPlayer and self.SelectedPlayer.Character then
		local humanoidRootPart = self.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			return humanoidRootPart
		end
	end
	return nil
end

function CameraManager:GetCFrameForViewingAngle(viewingAngle, selectedPlayerRootPart)
	if viewingAngle == VIEWING_ANGLE_FOLLOW then
		local followCFrame = selectedPlayerRootPart.CFrame * CFrame.Angles(math.rad(-15), 0, 0) * CFrame.new(0, -1, 12)
		local lookAtCFrame = selectedPlayerRootPart.CFrame * CFrame.Angles(math.rad(-5), 0, 0) * CFrame.new(0, -1, 4)
		return CFrame.new(followCFrame.p, lookAtCFrame.p)
	elseif viewingAngle == VIEWING_ANGLE_FRONT then
		return selectedPlayerRootPart.CFrame * CFrame.Angles(math.rad(30), math.rad(180), 0) * CFrame.new(0, -1, 7)
	end
end

function CameraManager:SwitchViewingAngle(newDesiredViewingAngle)
	self.DesiredViewingAngle = newDesiredViewingAngle
	self.CameraTweenTimeIn = 0
end

function CameraManager:UpdateCameraPosition(currentCamera, selectedPlayerRootPart, delta)
	local selectedPlayerPosition = selectedPlayerRootPart.Position
	if FOLLOW_FLIP_MODE_ENABLED then
		self.CameraTweenTimeIn = self.CameraTweenTimeIn + delta
		local newDesiredViewingAngle = self:GetDesiredViewingAngle(selectedPlayerPosition)
		if newDesiredViewingAngle == self.DesiredViewingAngle then
			if self.CameraTweenTimeIn > FLIP_CAMERA_ROTATE_TIME then
				currentCamera.CFrame = self:GetCFrameForViewingAngle(self.DesiredViewingAngle, selectedPlayerRootPart)
			else
				self:TweenCameraPosition(currentCamera, selectedPlayerRootPart)
			end
		else
			self:SwitchViewingAngle(newDesiredViewingAngle)
		end
	elseif FOLLOW_FRONT_VIEW then
		currentCamera.CFrame = self:GetCFrameForViewingAngle(VIEWING_ANGLE_FRONT, selectedPlayerRootPart)
	else
		currentCamera.CFrame = self:GetCFrameForViewingAngle(VIEWING_ANGLE_FOLLOW, selectedPlayerRootPart)
	end
end

function CameraManager:ConnectRenderSteppedFunction()
	self.RenderSteppedConnection = RunService.RenderStepped:connect(function(delta)
		local currentCamera = game.Workspace.CurrentCamera
		if not currentCamera then
			return
		end
		local selectedPlayerRootPart = self:GetSelectedPlayerRootPart()
		if not selectedPlayerRootPart then
			return
		end
		currentCamera.CameraSubject = selectedPlayerRootPart
		self:UpdateCameraPosition(currentCamera, selectedPlayerRootPart, delta)
	end)
end

function CameraManager:SetupFollowCamera()
	self.DidModifyCamera = true
	local currentCamera = Workspace.CurrentCamera
	if currentCamera then
		currentCamera.CameraType = Enum.CameraType.Scriptable
	end
	self:ConnectRenderSteppedFunction()
end

function CameraManager:ResetCamera()
	local currentCamera = game.Workspace.CurrentCamera
	if currentCamera then
		if LocalPlayer.Character then
			local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
			if humanoid then
				currentCamera.CameraSubject = humanoid
			end
		end
		currentCamera.CameraType = Enum.CameraType.Custom
	end
end

--- PUBLIC METHODS:
function CameraManager:ChangeSelectedPlayer(newSelectedPlayer)
	self.SelectedPlayer = newSelectedPlayer
	self.DesiredViewingAngle = VIEWING_ANGLE_FRONT
	self.LastPlayerPosition = Vector3.new(0, 0, 0)
	if newSelectedPlayer.Character then
		local selectedPlayerRootPlayer = newSelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
		if selectedPlayerRootPlayer then
			self.LastPlayerPosition = selectedPlayerRootPlayer.Position
		end
	end
	self.CameraTweenTimeIn = FLIP_CAMERA_ROTATE_TIME + 1
	self.LastCameraPlayerMoveTime = 0
	self.LastPositionReset = tick()
end

function CameraManager:DisabeCameraPanning()
	local currentCamera = Workspace.CurrentCamera
	if currentCamera then
		currentCamera.CameraType = Enum.CameraType.Scriptable
		self.DidModifyCamera = true
	end
end

function CameraManager:ContextMenuOpened()
	self.FollowCameraEnabled = self:GetFollowEnabled()
	if self.FollowCameraEnabled then
		self:SetupFollowCamera()
	end
end

function CameraManager:ContextMenuClosed()
	if self.RenderSteppedConnection then
		self.RenderSteppedConnection:Disconnect()
		self.RenderSteppedConnection = nil
	end
	if self.DidModifyCamera then
		self:ResetCamera()
		self.DidModifyCamera = false
	end
end

function CameraManager.new()
	local obj = setmetatable({}, CameraManager)

	obj.FollowCameraEnabled = false
	obj.DidModifyCamera = false
	obj.RenderSteppedConnection = nil

	obj.SelectedPlayer = nil
	obj.DesiredViewingAngle = VIEWING_ANGLE_FRONT
	obj.LastPlayerPosition = Vector3.new(0, 0, 0)
	obj.CameraTweenTimeIn = FLIP_CAMERA_ROTATE_TIME + 1
	obj.LastCameraPlayerMoveTime = 0
	obj.LastPositionReset = tick()

	return obj
end

return CameraManager.new()
