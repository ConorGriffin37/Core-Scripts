--[[
	// FileName: ContextMenuItems.lua
	// Written by: TheGamer101
	// Description: Module for creating the context menu items for the menu and doing the actions when they are clicked.
]]

-- CONSTANTS
local NAME_LAYOUT_ORDER = 1
local FRIEND_LAYOUT_ORDER = 2
local BLOCK_LAYOUT_ORDER = 3
local MUTE_LAYOUT_ORDER = 4
local REPORT_LAYOUT_ORDER = 5

local MENU_ITEM_SIZE_X = 0.9
local MENU_ITEM_SIZE_Y = 0.175

local THUMBNAIL_URL = "https://www.roblox.com/Thumbs/Avatar.ashx?x=200&y=200&format=png&userId="
local BUST_THUMBNAIL_URL = "https://www.roblox.com/bust-thumbnail/image?width=420&height=420&format=png&userId="

--- SERVICES
local PlayersService = game:GetService("Players")
local CoreGuiService = game:GetService("CoreGui")

-- MODULES
local RobloxGui = CoreGuiService:WaitForChild("RobloxGui")
local CoreGuiModules = RobloxGui:WaitForChild("Modules")
local SettingsModules = CoreGuiModules:WaitForChild("Settings")
local SettingsPages = SettingsModules:WaitForChild("Pages")

local PromptCreator = require(CoreGuiModules:WaitForChild("PromptCreator"))
local PlayerDropDownModule = require(CoreGuiModules:WaitForChild("PlayerDropDown"))
local ReportAbuseMenu = require(SettingsPages:WaitForChild("ReportAbuseMenu"))
local Utility = require(SettingsModules:WaitForChild("Utility"))

-- VARIABLES
local LocalPlayer = PlayersService.LocalPlayer
while not LocalPlayer do
	PlayersService.PlayerAdded:wait()
	LocalPlayer = PlayersService.LocalPlayer
end

local BlockingUtility = PlayerDropDownModule:CreateBlockingUtility()

local ContextMenuItems = {}
ContextMenuItems.__index = ContextMenuItems

-- PRIVATE METHODS

function ContextMenuItems:TryBlockPlayer(player)
	local successfullyBlocked = BlockingUtility:BlockPlayerAsync(player)
	if not successfullyBlocked then
		spawn(function()
			while PromptCreator:IsCurrentlyPrompting() do
				wait()
			end
			PromptCreator:CreatePrompt({
				WindowTitle = "Error Blocking Player",
				MainText = string.format("An error occurred while blocking %s. Please try again later.", player.Name),
				ConfirmationText = "Okay",
				CancelActive = false,
				Image = BUST_THUMBNAIL_URL ..player.UserId,
				ImageConsoleVR = THUMBNAIL_URL ..player.UserId,
				StripeColor = Color3.fromRGB(183, 34, 54),
			})
		end)
	end
	return successfullyBlocked
end

function ContextMenuItems:TryUnBlockPlayer(player)
	local successfullyUnblocked = BlockingUtility:UnblockPlayerAsync(player)
	if not successfullyUnblocked then
		spawn(function()
			while PromptCreator:IsCurrentlyPrompting() do
				wait()
			end
			PromptCreator:CreatePrompt({
				WindowTitle = "Error Unblocking Player",
				MainText = string.format("An error occurred while unblocking %s. Please try again later.", player.Name),
				ConfirmationText = "Okay",
				Image = BUST_THUMBNAIL_URL ..player.UserId,
				ImageConsoleVR = THUMBNAIL_URL ..player.UserId,
				StripeColor = Color3.fromRGB(183, 34, 54),
			})
		end)
	end
	return successfullyUnblocked
end

-- PUBLIC METHODS

function ContextMenuItems:CreateNameTag()
	local nameLabel = Instance.new("TextButton")
	nameLabel.Name = "NameTag"
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextSize = 24
	nameLabel.Font = Enum.Font.SourceSans
	nameLabel.TextColor3 = Color3.new(1,1,1)
	nameLabel.Text = self.SelectedPlayer.Name
	nameLabel.Size = UDim2.new(MENU_ITEM_SIZE_X, 0, MENU_ITEM_SIZE_Y, 0)
	nameLabel.LayoutOrder = NAME_LAYOUT_ORDER
	nameLabel.Parent = self.MenuItemFrame
end

function ContextMenuItems:CreateFriendButton(status)
	local friendLabel = self.MenuItemFrame:FindFirstChild("FriendStatus")
	if friendLabel then
		friendLabel:Destroy()
	end
	if status == Enum.FriendStatus.Friend or status == Enum.FriendStatus.FriendRequestSent then
		local friendLabel = Instance.new("TextButton")
		friendLabel.Name = "FriendStatus"
		friendLabel.BackgroundTransparency = 1
		friendLabel.TextSize = 24
		friendLabel.Font = Enum.Font.SourceSans
		friendLabel.TextColor3 = Color3.new(1,1,1)
		if status == Enum.FriendStatus.Friend then
			friendLabel.Text = "Friend"
		else
			friendLabel.Text = "Request Sent"
		end
		friendLabel.Size = UDim2.new(MENU_ITEM_SIZE_X, 0, MENU_ITEM_SIZE_Y, 0)
		friendLabel.LayoutOrder = FRIEND_LAYOUT_ORDER
		friendLabel.Parent = self.MenuItemFrame
	elseif status == Enum.FriendStatus.Unknown or status == Enum.FriendStatus.NotFriend or status == Enum.FriendStatus.FriendRequestReceived then
		local friendLabel, friendLabelText = nil, nil
		local addFriendFunc = function()
			if friendLabel and friendLabelText and friendLabelText.Text ~= "" then
				friendLabel.ImageTransparency = 1
				friendLabelText.Text = ""
				LocalPlayer:RequestFriendship(self.SelectedPlayer)
			end
		end
		friendLabel, friendLabelText = Utility:MakeStyledButton("FriendStatus", "Add Friend", UDim2.new(MENU_ITEM_SIZE_X, 0, MENU_ITEM_SIZE_Y, 0), addFriendFunc)
		friendLabel.Name = "FriendStatus"
		friendLabel.LayoutOrder = FRIEND_LAYOUT_ORDER
		friendLabel.Parent = self.MenuItemFrame
	end
end

function ContextMenuItems:CreateBlockButton(isBlocked)
	local blockLabel = self.MenuItemFrame:FindFirstChild("BlockStatus")
	if blockLabel then
		blockLabel:Destroy()
	end
	if not isBlocked then
		-- Block Button
		local blockButton, blockButtonText = nil, nil
		local function blockPlayerFunc()
			if blockButton and blockButtonText and blockButtonText.Text ~= "" then
				blockButton.ImageTransparency = 1
				blockButtonText.Text = ""
				local successfullyBlocked = self:TryBlockPlayer(self.SelectedPlayer)
				if not successfullyBlocked then
					blockButton.ImageTransparency = 0
					blockButtonText.Text = "Block"
				end
			end
		end
		blockButton, blockButtonText = Utility:MakeStyledButton("BlockStatus", "Block", UDim2.new(MENU_ITEM_SIZE_X, 0, MENU_ITEM_SIZE_Y, 0), blockPlayerFunc)
		blockButton.Name = "BlockStatus"
		blockButton.LayoutOrder = BLOCK_LAYOUT_ORDER
		blockButton.Parent = self.MenuItemFrame
	else
		-- UnBlock Button
		local unBlockButton, unBlockButtonText = nil, nil
		local function unBlockPlayerFunc()
			if unBlockButton and unBlockButtonText and unBlockButtonText.Text ~= "" then
				unBlockButton.ImageTransparency = 1
				unBlockButtonText.Text = ""
				local successfullyUnblocked = self:TryUnBlockPlayer(self.SelectedPlayer)
				if not successfullyUnblocked then
					unBlockButton.ImageTransparency = 0
					unBlockButtonText.Text = "Block"
				end
			end
		end
		unBlockButton, unBlockButtonText = Utility:MakeStyledButton("BlockStatus", "Unblock", UDim2.new(MENU_ITEM_SIZE_X, 0, MENU_ITEM_SIZE_Y, 0), unBlockPlayerFunc)
		unBlockButton.Name = "BlockStatus"
		unBlockButton.LayoutOrder = BLOCK_LAYOUT_ORDER
		unBlockButton.Parent = self.MenuItemFrame
	end
end

function ContextMenuItems:CreateMuteButton(isMuted)
	local muteLabel = self.MenuItemFrame:FindFirstChild("MuteStatus")
	if muteLabel then
		muteLabel:Destroy()
	end
	if not isMuted then
		local muteButton, muteButtonText = nil, nil
		local function mutePlayerFunc()
			if muteButton and muteButtonText and muteButtonText.Text ~= "" then
				muteButton.ImageTransparency = 1
				muteButtonText.Text = ""
				BlockingUtility:MutePlayer(self.SelectedPlayer)
			end
		end
		muteButton, muteButtonText = Utility:MakeStyledButton("MuteStatus", "Mute", UDim2.new(MENU_ITEM_SIZE_X, 0, MENU_ITEM_SIZE_Y, 0), mutePlayerFunc)
		muteButton.Name = "MuteStatus"
		muteButton.LayoutOrder = MUTE_LAYOUT_ORDER
		muteButton.Parent = self.MenuItemFrame
	else
		local unMuteButton, unMuteButtonText = nil, nil
		local function unmutePlayerFunc()
			if unMuteButton and unMuteButtonText and unMuteButtonText.Text ~= "" then
				unMuteButton.ImageTransparency = 1
				unMuteButtonText.Text = ""
				BlockingUtility:UnmutePlayer(self.SelectedPlayer)
			end
		end
		unMuteButton, unMuteButtonText = Utility:MakeStyledButton("MuteStatus", "Unmute", UDim2.new(MENU_ITEM_SIZE_X, 0, MENU_ITEM_SIZE_Y, 0), unmutePlayerFunc)
		unMuteButton.Name = "MuteStatus"
		unMuteButton.LayoutOrder = MUTE_LAYOUT_ORDER
		unMuteButton.Parent = self.MenuItemFrame
	end
end

function ContextMenuItems:CreateReportButton()
	local function reportPlayerFunc()
		ReportAbuseMenu:ReportPlayer(self.SelectedPlayer)
	end
	local reportButton = Utility:MakeStyledButton("ReportPlayer", "Report Abuse", UDim2.new(MENU_ITEM_SIZE_X, 0, MENU_ITEM_SIZE_Y, 0), reportPlayerFunc)
	reportButton.Name = "ReportPlayer"
	reportButton.Modal = true
	reportButton.LayoutOrder = REPORT_LAYOUT_ORDER
	reportButton.Parent = self.MenuItemFrame
end

function ContextMenuItems:ClearMenuItems()
	local children = self.MenuItemFrame:GetChildren()
	for i = 1, #children do
		if children[i]:IsA("GuiObject") then
			children[i]:Destroy()
		end
	end
end

function ContextMenuItems:SetSelectedPlayer(selectedPlayer)
	self.SelectedPlayer = selectedPlayer
end

function ContextMenuItems.new(menuItemFrame)
	local obj = setmetatable({}, ContextMenuItems)

	obj.MenuItemFrame = menuItemFrame
	obj.SelectedPlayer = nil

	return obj
end

return ContextMenuItems
