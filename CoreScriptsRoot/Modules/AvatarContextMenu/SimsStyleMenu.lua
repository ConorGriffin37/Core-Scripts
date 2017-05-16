--[[
	// FileName: SimsStyleMenu.lua
	// Written by: TheGamer101
	// Description: Module for sims style menu prototype.
]]

-- CONSTANTS

local BUTTON_SIZE_Y = 36
local BUTTON_BACKGROUND_COLOR = Color3.fromRGB(255, 255, 255)

local BUTTON_CENTER_OFFSET = 45

local BUTTON_POSITION_RIGHT = 1
local BUTTON_POSITION_LEFT = 2
local BUTTON_POSITION_DOWN = 3
local BUTTON_POSITION_UP = 4

-- SERVICES

local Workspace = game:GetService("Workspace")
local PlayersService = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGuiService = game:GetService("CoreGui")
local TextService = game:GetService("TextService")

-- MODULES
local RobloxGui = CoreGuiService:WaitForChild("RobloxGui")
local CoreGuiModules = RobloxGui:WaitForChild("Modules")
local SettingsModules = CoreGuiModules:WaitForChild("Settings")
local AvatarMenuModules = CoreGuiModules:WaitForChild("AvatarContextMenu")
local SettingsPages = SettingsModules:WaitForChild("Pages")

local ContextMenuItemsModule = require(AvatarMenuModules:WaitForChild("ContextMenuItems"))
local ReportAbuseMenu = require(SettingsPages:WaitForChild("ReportAbuseMenu"))

local PlayerDropDownModule = require(CoreGuiModules:WaitForChild("PlayerDropDown"))

-- VARIABLES
local LocalPlayer = PlayersService.LocalPlayer
while not LocalPlayer do
	PlayersService.PlayerAdded:wait()
	LocalPlayer = PlayersService.LocalPlayer
end

local ContextMenuItems = ContextMenuItemsModule.new()

local BlockingUtility = PlayerDropDownModule:CreateBlockingUtility()

local SimsStyleMenu = {}
SimsStyleMenu.__index = SimsStyleMenu

-- PRIVATE METHODS:

function SimsStyleMenu:PositionButton(button, position)
	if position == BUTTON_POSITION_RIGHT then
		button.AnchorPoint = Vector2.new(0, 0.5)
		button.Position = UDim2.new(0, BUTTON_CENTER_OFFSET, 0, 0)
	elseif position == BUTTON_POSITION_LEFT then
		button.AnchorPoint = Vector2.new(1, 0.5)
		button.Position = UDim2.new(0, -BUTTON_CENTER_OFFSET, 0, 0)
	elseif position == BUTTON_POSITION_UP then
		button.AnchorPoint = Vector2.new(0.5, 1)
		button.Position = UDim2.new(0, 0, 0, -BUTTON_CENTER_OFFSET)
	elseif position == BUTTON_POSITION_DOWN then
		button.AnchorPoint = Vector2.new(0.5, 0)
		button.Position = UDim2.new(0, 0, 0, BUTTON_CENTER_OFFSET)
	end
end

function SimsStyleMenu:CreateButton(name, text)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 150, 0, BUTTON_SIZE_Y)
	button.Name = name
	button.Font = Enum.Font.SourceSansBold
	button.TextXAlignment = Enum.TextXAlignment.Center
	button.TextYAlignment = Enum.TextYAlignment.Center
	button.TextSize = 18
	button.TextColor3 = Color3.new(0, 170, 255)
	button.TextStrokeTransparency = 1
	button.BackgroundTransparency = 1
	button.ZIndex = 1
	button.Text = text
	local textBounds = TextService:GetTextSize(text, 18, Enum.Font.SourceSansBold, Vector2.new(1000, 1000))
	button.Size = UDim2.new(0, textBounds.X + 30, 0, BUTTON_SIZE_Y)

	local background = Instance.new("ImageLabel")
	background.Name = "Background"
	background.BackgroundTransparency = 1
	background.Position = UDim2.new(0, 0, 0, 0)
	background.Size = UDim2.new(1, 0, 1, 0)
	background.Image = "rbxassetid://296436115"
	background.ImageColor3 = BUTTON_BACKGROUND_COLOR
	background.ScaleType = Enum.ScaleType.Slice
	background.SliceCenter = Rect.new(15, 17, 206, 19)
	background.ZIndex = 0
	background.Parent = button

	return button
end

function SimsStyleMenu:HideButton(button)
	button.TextTransparency = 1
	button.Background.ImageTransparency = 1
end

function SimsStyleMenu:CreateFriendButton(status)
	if self.FriendButton then
		self.FriendButton:Destroy()
	end
	if status == Enum.FriendStatus.Friend then
		local button = self:CreateButton("FriendStatus", "Friend")
		button.Parent = self.SimStyleMenuFrame
		self.FriendButton = button
	elseif status == Enum.FriendStatus.FriendRequestSent then
		local button = self:CreateButton("FriendStatus", "Friend Request Sent")
		button.Parent = self.SimStyleMenuFrame
		self.FriendButton = button
	elseif status == Enum.FriendStatus.Unknown or status == Enum.FriendStatus.NotFriend or status == Enum.FriendStatus.FriendRequestReceived then
		local button = self:CreateButton("FriendStatus", "Add Friend")
		button.Parent = self.SimStyleMenuFrame
		local addFriendFunc = function()
			if button.TextTransparency ~= 1 then
				self:HideButton(button)
				LocalPlayer:RequestFriendship(self.SelectedPlayer)
			end
		end
		button.MouseButton1Click:connect(addFriendFunc)
		self.FriendButton = button
	end
	self:PositionButton(self.FriendButton, BUTTON_POSITION_UP)
end

function SimsStyleMenu:CreateBlockButton(isBlocked)
	if self.BlockButton then
		self.BlockButton:Destroy()
	end
	if isBlocked then
		local button = self:CreateButton("BlockStatus", "Unblock")
		button.Parent = self.SimStyleMenuFrame
		local function unBlockPlayerFunc()
			if button.TextTransparency ~= 1 then
				self:HideButton(button)
				ContextMenuItems:TryUnBlockPlayer(self.SelectedPlayer)
			end
		end
		button.MouseButton1Click:connect(unBlockPlayerFunc)
		self.BlockButton = button
	else
		local button = self:CreateButton("BlockStatus", "Block")
		button.Parent = self.SimStyleMenuFrame
		local function blockPlayerFunc()
			if button.TextTransparency ~= 1 then
				self:HideButton(button)
				ContextMenuItems:TryBlockPlayer(self.SelectedPlayer)
			end
		end
		button.MouseButton1Click:connect(blockPlayerFunc)
		self.BlockButton = button
	end
	self:PositionButton(self.BlockButton, BUTTON_POSITION_DOWN)
end

function SimsStyleMenu:CreateMuteButton(isMuted)
	if self.MuteButton then
		self.MuteButton:Destroy()
	end
	if isMuted then
		local button = self:CreateButton("MuteStatus", "Unmute")
		button.Parent = self.SimStyleMenuFrame
		local function unMutePlayerFunc()
			if button.TextTransparency ~= 1 then
				self:HideButton(button)
				BlockingUtility:UnmutePlayer(self.SelectedPlayer)
			end
		end
		button.MouseButton1Click:connect(unMutePlayerFunc)
		self.MuteButton = button
	else
		local button = self:CreateButton("MuteStatus", "Mute")
		button.Parent = self.SimStyleMenuFrame
		local function mutePlayerFunc()
			if button.TextTransparency ~= 1 then
				self:HideButton(button)
				BlockingUtility:MutePlayer(self.SelectedPlayer)
			end
		end
		button.MouseButton1Click:connect(mutePlayerFunc)
		self.MuteButton = button
	end
	self:PositionButton(self.MuteButton, BUTTON_POSITION_LEFT)
end

function SimsStyleMenu:CreateReportButton()
	if self.ReportButton then
		self.ReportButton:Destroy()
	end
	local function reportPlayerFunc()
		ReportAbuseMenu:ReportPlayer(self.SelectedPlayer)
	end
	local button = self:CreateButton("ReportAbuse", "Report Abuse")
	button.Parent = self.SimStyleMenuFrame
	button.MouseButton1Click:connect(reportPlayerFunc)
	self.ReportButton = button
	self:PositionButton(self.ReportButton, BUTTON_POSITION_RIGHT)
end

function GetFriendStatus(player)
	local success, result = pcall(function()
		-- NOTE: Core script only
		return LocalPlayer:GetFriendStatus(player)
	end)
	if success then
		return result
	else
		return Enum.FriendStatus.NotFriend
	end
end

function SimsStyleMenu:BuildMenu(player)
	local friendStatus = GetFriendStatus(player)
	local isBlocked = BlockingUtility:IsPlayerBlockedByUserId(player.UserId)
	local isMuted = BlockingUtility:IsPlayerMutedByUserId(player.UserId)
	self:CreateFriendButton(friendStatus)
	self:CreateBlockButton(isBlocked)
	self:CreateMuteButton(isMuted)
	self:CreateReportButton()
end

function SimsStyleMenu:GetSelectedPlayerPosition()
	if self.SelectedPlayer and self.SelectedPlayer.Character then
		local humnanoidRootPart = self.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
		if humnanoidRootPart then
			return humnanoidRootPart.Position
		end
	end
end

--- Returns bool isVisible, Vector2 screenPoint
function SimsStyleMenu:WorldSpaceToScreenSpace(worldPoint)
	local currentCamera = Workspace.CurrentCamera
	if currentCamera then
		local screenPoint = currentCamera:WorldToScreenPoint(worldPoint)
		return screenPoint.Z >= 0, Vector2.new(screenPoint.X, screenPoint.Y)
	end
	return false, Vector2.new(0, 0)
end

function SimsStyleMenu:HideContextMenu()
	self.FriendButton.Visible = false
	self.BlockButton.Visible = false
	self.MuteButton.Visible = false
	self.ReportButton.Visible = false
end

function SimsStyleMenu:DisplayContextMenu()
	self.FriendButton.Visible = true
	self.BlockButton.Visible = true
	self.MuteButton.Visible = true
	self.ReportButton.Visible = true
end

function SimsStyleMenu:UpdateMenuPosition()
	local playerPosition = self:GetSelectedPlayerPosition()
	if playerPosition then
		local isVisible, screenPoint = self:WorldSpaceToScreenSpace(playerPosition)
		if isVisible then
			self:DisplayContextMenu()
			self.SimStyleMenuFrame.Position = UDim2.new(0, screenPoint.X, 0, screenPoint.Y)
		else
			self:HideContextMenu()
		end
	else
		self:HideContextMenu()
	end
end

function SimsStyleMenu:CreateCenterFrame(parent)
	local frame = Instance.new("Frame")
	frame.Name = "SimsMenuFrame"
	frame.Size = UDim2.new(0, 0, 0, 0)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.ClipsDescendants = false
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	return frame
end

-- PUBLIC_METHODS:

function SimsStyleMenu:ContextMenuOpened(selectedPlayer)
	self.SelectedPlayer = selectedPlayer
	self:BuildMenu(selectedPlayer)
	self:UpdateMenuPosition()
	self.ContextMenuFrame.Visible = true
	self.SimStyleMenuFrame.Visible = true
	self.RenderSteppedConnection = RunService.RenderStepped:connect(function()
		self:UpdateMenuPosition()
	end)
end

function SimsStyleMenu:ContextMenuClosed()
	self:HideContextMenu()
	self.ContextMenuFrame.Visible = false
	self.SimStyleMenuFrame.Visible = false
	self.RenderSteppedConnection:Disconnect()
end

function SimsStyleMenu.new(contextMenuFrame)
	local obj = setmetatable({}, SimsStyleMenu)

	obj.ContextMenuFrame = contextMenuFrame
	obj.SelectedPlayer = nil
	obj.SimStyleMenuFrame = obj:CreateCenterFrame(contextMenuFrame)

	-- Context Buttons
	obj.FriendButton = nil
	obj.BlockButton = nil
	obj.MuteButton = nil
	obj.ReportButton = nil

	return obj
end

return SimsStyleMenu
