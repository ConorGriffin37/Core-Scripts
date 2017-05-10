--[[
	// FileName: SimsStyleMenu.lua
	// Written by: TheGamer101
	// Description: Module for sims style menu prototype.
]]

-- CONSTANTS

local BUTTON_SIZE_Y = 36
local BUTTON_BACKGROUND_COLOR = Color3.fromRGB(255, 255, 255)

-- SERVICES

local PlayersService = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGuiService = game:GetService("CoreGui")

-- MODULES
local RobloxGui = CoreGuiService:WaitForChild("RobloxGui")
local CoreGuiModules = RobloxGui:WaitForChild("Modules")
local SettingsModules = CoreGuiModules:WaitForChild("Settings")
local AvatarMenuModules = CoreGuiModules:WaitForChild("AvatarContextMenu")

local ContextMenuItemsModule = require(AvatarMenuModules:WaitForChild("ContextMenuItems"))

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
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Text = text

	button.Size = UDim2.new(0, button.TextBounds.X + 30, 0, BUTTON_SIZE_Y)

	local background = Instance.new("ImageLabel")
	background.BackgroundTransparency = 1
	background.Position = UDim2.new(0, 0, 0, 0)
	background.Size = UDim2.new(1, 0, 1, 0)
	background.Image = "rbxassetid://296436115"
	background.ImageColor3 = BUTTON_BACKGROUND_COLOR
	background.ScaleType = Enum.ScaleType.Slice
	background.SliceCenter = Rect.new(15, 17, 206, 19)
	background.Parent = button

	return button
end

function SimsStyleMenu:CreateFriendButton(status)
	if self.FriendButton then
		self.FriendButton:Destroy()
	end
	-- TODO: Take status into account
	local addFriendFunc = function()
		LocalPlayer:RequestFriendship(self.SelectedPlayer)
	end
	local button = self:CreateButton("FriendStatus", "Add Friend")
	button.Parent = self.ContextMenuFrame
	button.MouseButton1Click:connect(addFriendFunc)
	self.FriendButton = button
end

function SimsStyleMenu:CreateBlockButton(isBlocked)
	if self.BlockButton then
		self.BlockButton:Destroy()
	end
	if isBlocked then
		local function unBlockPlayerFunc()
			ContextMenuItems:TryUnBlockPlayer(self.SelectedPlayer)
		end
		local button = self:CreateButton("BlockStatus", "Unblock")
		button.Parent = self.ContextMenuFrame
		button.MouseButton1Click:connect(unBlockPlayerFunc)
		self.BlockButton = button
	else
		local function blockPlayerFunc()
			ContextMenuItems:TryUnBlockPlayer(self.SelectedPlayer)
		end
		local button = self:CreateButton("BlockStatus", "Block")
		button.Parent = self.ContextMenuFrame
		button.MouseButton1Click:connect(blockPlayerFunc)
		self.BlockButton = button
	end
end

function SimsStyleMenu:CreateMuteButton(isMuted)
	if self.MuteButton then
		self.MuteButton:Destroy()
	end
	if isMuted then
		local function unMutePlayerFunc()
			BlockingUtility:UnmutePlayer(self.SelectedPlayer)
		end
		local button = self:CreateButton("MuteStatus", "Unmute")
		button.Parent = self.ContextMenuFrame
		button.MouseButton1Click:connect(unMutePlayerFunc)
		self.MuteButton = button
	else
		local function mutePlayerFunc()
			BlockingUtility:MutePlayer(self.SelectedPlayer)
		end
		local button = self:CreateButton("MuteStatus", "Mute")
		button.Parent = self.ContextMenuFrame
		button.MouseButton1Click:connect(mutePlayerFunc)
		self.MuteButton = button
	end
end

function SimsStyleMenu:CreateReportButton()
	if self.ReportButton then
		self.ReportButton:Destroy()
	end
	local function reportPlayerFunc()
		ReportAbuseMenu:ReportPlayer(self.SelectedPlayer)
	end
	local button = self:CreateButton("ReportAbuse", "Report Abuse")
	button.Parent = self.ContextMenuFrame
	button.MouseButton1Click:conenct(reportPlayerFunc)
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

-- PUBLIC_METHODS:

function SimsStyleMenu:SetSelectedPlayer(selectedPlayer)
	self.SelectedPlayer = selectedPlayer
end

function SimsStyleMenu.new(contextMenuFrame)
	local obj = setmetatable({}, SimsStyleMenu)

	obj.ContextMenuFrame = contextMenuFrame
	obj.SelectedPlayer = nil

	-- Context Buttons
	obj.FriendButton = nil
	obj.BlockButton = nil
	obj.MuteButton = nil
	obj.ReportButton = nil

	return obj
end

return SimsStyleMenu.new()
