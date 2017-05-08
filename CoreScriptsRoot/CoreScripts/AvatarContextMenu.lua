--[[
	// FileName: AvatarContextMenu.lua
	// Written by: TheGamer101
	// Description: A context menu to allow users to click on avatars and then interact with that user.
]]

-- OPTIONS
local DEBUG_MODE = true

-- CONSTANTS
local CONEXT_MENU_DISPLAY_ORDER = 7
local MAX_CONTEXT_MENU_DISTANCE = 100

local BG_TRANSPARENCY = 0.5
local BG_COLOR = Color3.fromRGB(31, 31, 31)

local BOTTOM_SCREEN_PADDING_PERCENT = 0.10

local MAX_WIDTH = 250
local MAX_HEIGHT = 300
local MAX_WIDTH_PERCENT = 0.7
local MAX_HEIGHT_PERCENT = 0.6

local PLAYER_ICON_SIZE_Y = 0.3
local LIST_SIZE_Y = 0.67

local BUTTON_PADDING = 0.025

local LEAVE_BUTTON_SIZE_Y = 0.125

local OPEN_MENU_TIME = 0.5
local OPEN_MENU_TWEEN = TweenInfo.new(OPEN_MENU_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

local SWIPE_AWAY_TIME = 0.2
local SWIPE_MENU_AWAY_TWEEN = TweenInfo.new(SWIPE_AWAY_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SWIPE_IN_TIME = 0.2
local SWIPE_MENU_IN_TWEEN = TweenInfo.new(SWIPE_IN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local MAX_THUMBNAIL_WAIT_TIME = 2

local LEAVE_MENU_ACTION_NAME = "EscapeAvatarContextMenu"
local STOP_MOVEMENT_ACTION_NAME = "AvatarContextMenuStopInput"
local SWITCH_PLAYER_LEFT_ACTION_NAME = "AvatarSelectPlayerLeft"
local SWITCH_PLAYER_RIGHT_ACTION_NAME = "AvatarSelectPlayerRight"

local CONTEXT_MENU_DEBOUNCE = 0.3  -- Time before you can reopen the menu after closing it.

-- SERVICES
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local PlayerService = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local CoreGuiService = game:GetService("CoreGui")

--- MODULES
local RobloxGui = CoreGuiService:WaitForChild("RobloxGui")
local CoreGuiModules = RobloxGui:WaitForChild("Modules")
local SettingsModules = CoreGuiModules:WaitForChild("Settings")
local AvatarMenuModules = CoreGuiModules:WaitForChild("AvatarContextMenu")

local CameraManager = require(AvatarMenuModules:WaitForChild("CameraManager"))
local ContextMenuItemsModule = require(AvatarMenuModules:WaitForChild("ContextMenuItems"))

local PlayerDropDownModule = require(CoreGuiModules:WaitForChild("PlayerDropDown"))
local Utility = require(SettingsModules:WaitForChild("Utility"))

local LocalPlayer = PlayerService.LocalPlayer
while not LocalPlayer do
	PlayerService.PlayerAdded:wait()
	LocalPlayer = PlayerService.LocalPlayer
end

--- VARIABLES

local BlockingUtility = PlayerDropDownModule:CreateBlockingUtility()

local ContextMenuItems = nil

local ContextMenuHolder = nil
local ContextMenuFrame = nil

local ContextMenuOpening = false
local DoingCarouselSwipe = false

local ContextMenuOpen = false
local SelectedPlayer = nil
local PlayerCarousel = {}
local PlayerCarouselIndex = 1

local HeadShotUrlCache = {}

local TouchSwipeConnection = nil

local OldJumpPower = nil
local OldWalkSpeed = nil

ContextMenuHolder = Instance.new("Frame")
ContextMenuHolder.Name = "AvatarContextMenu"
ContextMenuHolder.Position = UDim2.new(0, 0, 0, 0)
ContextMenuHolder.Size = UDim2.new(1, 0, 1, 0)
ContextMenuHolder.BackgroundTransparency = 1
ContextMenuHolder.Parent = RobloxGui

function CreateLeaveMenuButton(frame)
	local function closeMenu()
		CloseContextMenu()
	end

	local closeMenuButton = Utility:MakeStyledButton("CloseMenuButton", "X", UDim2.new(1, 0, LEAVE_BUTTON_SIZE_Y, 0), closeMenu)
	closeMenuButton.AnchorPoint = Vector2.new(1, 0)
	closeMenuButton.Position = UDim2.new(1 - BUTTON_PADDING, 0, BUTTON_PADDING, 0)
	closeMenuButton.Parent = frame

	local aspectConstraint = Instance.new("UIAspectRatioConstraint")
	aspectConstraint.AspectType = Enum.AspectType.FitWithinMaxSize
	aspectConstraint.DominantAxis = Enum.DominantAxis.Height
	aspectConstraint.AspectRatio = 1
	aspectConstraint.Parent = closeMenuButton

	return closeMenuButton
end

function CreateSwitchPlayerArrows(frame)
	local leftArrowLabel = Instance.new("ImageLabel")
	leftArrowLabel.Name = "LeftArrowLabel"
	leftArrowLabel.BackgroundTransparency = 1
	leftArrowLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	leftArrowLabel.Rotation = 180
	leftArrowLabel.Position = UDim2.new(-0.1, 0, 0.5, 0)
	leftArrowLabel.Size = UDim2.new(0.1, 0, 0.1, 0)
	leftArrowLabel.Image = "rbxassetid://471630112"
	leftArrowLabel.Parent = frame

	local rightArrowLabel = leftArrowLabel:Clone()
	rightArrowLabel.Name = "RightArrowLabel"
	rightArrowLabel.Rotation = 0
	rightArrowLabel.Position =  UDim2.new(1.1, 0, 0.5, 0)
	rightArrowLabel.Parent = frame

	local aspectConstraint = Instance.new("UIAspectRatioConstraint")
	aspectConstraint.AspectType = Enum.AspectType.FitWithinMaxSize
	aspectConstraint.DominantAxis = Enum.DominantAxis.Width
	aspectConstraint.AspectRatio = 1
	aspectConstraint.Parent = leftArrowLabel

	aspectConstraint:Clone().Parent = rightArrowLabel
end

function CreateMenuFrame()
	local frame = Instance.new("Frame")
	frame.Name = "Menu"
	frame.Size = UDim2.new(MAX_WIDTH_PERCENT, 0, MAX_HEIGHT_PERCENT, 0)
	frame.Position = UDim2.new(0.5, 0, 1 - BOTTOM_SCREEN_PADDING_PERCENT, 0)
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.BackgroundColor3 = BG_COLOR
	frame.BackgroundTransparency = BG_TRANSPARENCY
	frame.Visible = false
	frame.Parent = ContextMenuHolder

	local aspectConstraint = Instance.new("UIAspectRatioConstraint")
	aspectConstraint.AspectType = Enum.AspectType.FitWithinMaxSize
	aspectConstraint.DominantAxis = Enum.DominantAxis.Width
	aspectConstraint.AspectRatio = MAX_WIDTH/MAX_HEIGHT
	aspectConstraint.Parent = frame

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(MAX_WIDTH, MAX_HEIGHT)
	sizeConstraint.Parent = frame

	local listFrame = Instance.new("Frame")
	listFrame.Name = "ContextActionList"
	listFrame.BackgroundTransparency = 1
	listFrame.Size = UDim2.new(1, 0, LIST_SIZE_Y, 0)
	listFrame.Position = UDim2.new(0, 0, 1, 0)
	listFrame.AnchorPoint = Vector2.new(0, 1)
	listFrame.Parent = frame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(BUTTON_PADDING, 0)
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = listFrame

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 1
	uiScale.Parent = frame

	CreateLeaveMenuButton(frame)
	CreateSwitchPlayerArrows(frame)

	return frame
end

ContextMenuFrame = CreateMenuFrame()
ContextMenuItems = ContextMenuItemsModule.new(ContextMenuFrame.ContextActionList)

function CreatePlayerIcon(player)
	local oldPlayerIcon = ContextMenuFrame:FindFirstChild("PlayerIcon")
	if oldPlayerIcon then
		oldPlayerIcon.Image = ""
		coroutine.wrap(function()
			local headshotUrl = GetHeadshotForPlayer(player)
			if headshotUrl and player == SelectedPlayer then
				oldPlayerIcon.Image = headshotUrl
			end
		end)()
		return oldPlayerIcon
	end

	local playerIcon = Instance.new("ImageLabel")
	playerIcon.Name = "PlayerIcon"
	playerIcon.Position = UDim2.new(0.5, 0, (1 - LIST_SIZE_Y)/2, 0)
	playerIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	playerIcon.Size = UDim2.new(1, 0, PLAYER_ICON_SIZE_Y, 0)
	playerIcon.BackgroundTransparency = 1
	playerIcon.Image = ""
	coroutine.wrap(function()
		local headshotUrl = GetHeadshotForPlayer(player)
		if headshotUrl and player == SelectedPlayer then
			playerIcon.Image = headshotUrl
		end
	end)()
	playerIcon.Parent = ContextMenuFrame

	local aspectConstraint = Instance.new("UIAspectRatioConstraint")
	aspectConstraint.AspectType = Enum.AspectType.FitWithinMaxSize
	aspectConstraint.DominantAxis = Enum.DominantAxis.Height
	aspectConstraint.AspectRatio = 1
	aspectConstraint.Parent = playerIcon

	return playerIcon
end

--- Friend Functions
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

LocalPlayer.FriendStatusChanged:connect(function(player, friendStatus)
	if player and player == SelectedPlayer then
		ContextMenuItems:CreateFriendButton(friendStatus)
	end
end)

-- Blocking Functions

BlockingUtility:GetBlockedStatusChangedEvent():connect(function(userId, isBlocked)
	if SelectedPlayer and SelectedPlayer.UserId == userId then
		ContextMenuItems:CreateBlockButton(isBlocked)
	end
end)

-- Muting Functions
BlockingUtility:GetMutedStatusChangedEvent():connect(function(userId, isMuted)
	if SelectedPlayer and SelectedPlayer.UserId == userId then
		ContextMenuItems:CreateMuteButton(isMuted)
	end
end)

function GetHeadshotForPlayer(player)
	if HeadShotUrlCache[player] ~= nil and HeadShotUrlCache[player] ~= "" then
		return HeadShotUrlCache[player]
	end
	local startTime = tick()
	local headshotUrl, isFinal = PlayerService:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
	while not isFinal do
		if tick() - startTime > MAX_THUMBNAIL_WAIT_TIME then
			return headshotUrl
		end
		headshotUrl, isFinal = PlayerService:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
	end
	HeadShotUrlCache[player] = headshotUrl
	return headshotUrl
end

function BuildMenuForPlayer(player)
	local friendStatus = GetFriendStatus(player)
	local isBlocked = BlockingUtility:IsPlayerBlockedByUserId(player.UserId)
	local isMuted = BlockingUtility:IsPlayerMutedByUserId(player.UserId)
	CreatePlayerIcon(player)
	ContextMenuItems:ClearMenuItems()
	ContextMenuItems:SetSelectedPlayer(player)
	ContextMenuItems:CreateNameTag()
	ContextMenuItems:CreateFriendButton(friendStatus)
	ContextMenuItems:CreateBlockButton(isBlocked)
	ContextMenuItems:CreateMuteButton(isMuted)
	ContextMenuItems:CreateReportButton(player)
end

function DisablePlayerMovement()
	local noOpFunc = function() end
	ContextActionService:BindAction(STOP_MOVEMENT_ACTION_NAME, noOpFunc, false,
		Enum.PlayerActions.CharacterForward,
		Enum.PlayerActions.CharacterBackward,
		Enum.PlayerActions.CharacterLeft,
		Enum.PlayerActions.CharacterRight,
		Enum.PlayerActions.CharacterJump,
		Enum.KeyCode.LeftShift,
		Enum.KeyCode.RightShift,
		Enum.KeyCode.Tab,
		Enum.UserInputType.Gamepad1, Enum.UserInputType.Gamepad2, Enum.UserInputType.Gamepad3, Enum.UserInputType.Gamepad4
	)

	if LocalPlayer.Character then
		local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
		if humanoid then
			OldJumpPower = humanoid.JumpPower
			OldWalkSpeed = humanoid.WalkSpeed
			humanoid.JumpPower = 0
			humanoid.WalkSpeed = 0
		end
	end
end

function EnablePlayerMovement()
	if LocalPlayer.Character then
		local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
		if humanoid then
			if OldJumpPower and OldWalkSpeed then
				humanoid.JumpPower = OldJumpPower
				humanoid.WalkSpeed = OldWalkSpeed
			end
		end
	end
end

function Open2DMenu(player, screenPoint)
	ContextMenuOpening = true
	CameraManager:ChangeSelectedPlayer(player)
	BuildMenuForPlayer(player)
	ContextMenuFrame.Visible = true

	local menuScale = ContextMenuFrame:FindFirstChild("UIScale")
	ContextMenuFrame.Position = UDim2.new(0, screenPoint.X, 0, screenPoint.Y)
	menuScale.Scale = 0.1
	local positionTween = TweenService:Create(ContextMenuFrame, OPEN_MENU_TWEEN, {["Position"] = UDim2.new(0.5, 0, 1 - BOTTOM_SCREEN_PADDING_PERCENT, 0)})
	local sizeTween = TweenService:Create(menuScale, OPEN_MENU_TWEEN, {["Scale"] = 1})
	positionTween:Play()
	sizeTween:Play()
	positionTween.Completed:wait()
	if sizeTween.PlaybackState ~= Enum.PlaybackState.Completed then
		sizeTween.Completed:wait()
	end
	ContextMenuOpening = false
end

function BindMenuActions()
	-- Close Menu actions
	local closeMenuFunc = function(actionName, inputState, input)
		if inputState ~= Enum.UserInputState.Begin then
			return
		end
		CloseContextMenu()
	end
	ContextActionService:BindCoreAction(LEAVE_MENU_ACTION_NAME, closeMenuFunc, false, Enum.KeyCode.Escape)

	-- Carousel Movement
	local function switchPlayerLeftFunc(actionName, inputState, input)
		if inputState ~= Enum.UserInputState.Begin then
			return
		end
		MovePlayerCarousel(-1)
	end
	ContextActionService:BindCoreAction(SWITCH_PLAYER_LEFT_ACTION_NAME, switchPlayerLeftFunc, false, Enum.KeyCode.Left)
	local function switchPlayerRightFunc(actionName, inputState, input)
		if inputState ~= Enum.UserInputState.Begin then
			return
		end
		MovePlayerCarousel(1)
	end
	ContextActionService:BindCoreAction(SWITCH_PLAYER_RIGHT_ACTION_NAME, switchPlayerRightFunc, false, Enum.KeyCode.Right)
end

function UnBindContextActions()
	-- Enable movement
	ContextActionService:UnbindAction(STOP_MOVEMENT_ACTION_NAME)
	ContextActionService:UnbindCoreAction(LEAVE_MENU_ACTION_NAME)
	ContextActionService:UnbindCoreAction(SWITCH_PLAYER_LEFT_ACTION_NAME)
	ContextActionService:UnbindCoreAction(SWITCH_PLAYER_RIGHT_ACTION_NAME)
end

function ChangeSelectedPlayer(newPlayer)
	while ContextMenuOpening do
		wait()
	end
	if not ContextMenuOpen or newPlayer == SelectedPlayer then
		return
	end
	if PlayerCarousel[PlayerCarouselIndex] ~= newPlayer then
		return
	end
	ContextMenuOpening = true
	SelectedPlayer = newPlayer
	ContextMenuItems:SetSelectedPlayer(newPlayer)
	CameraManager:ChangeSelectedPlayer(newPlayer)
	BuildMenuForPlayer(newPlayer)
	ContextMenuOpening = false
end

function ClampCarouselIndex(index)
	if #PlayerCarousel == 1 then
		return 1
	end
	return ((index - 1) % #PlayerCarousel) + 1
end

function OnCaroselIndexChanged(newIndex)
	-- Expand HeadshotUrl cache
	for i = newIndex - 3, newIndex + 3 do
		local index = ClampCarouselIndex(i)
		if index ~= newIndex then
			local player = PlayerCarousel[index]
			coroutine.wrap(function()
				if HeadShotUrlCache[player] == nil then
					HeadShotUrlCache[player] = ""
					GetHeadshotForPlayer(player)
				end
			end)()
		end
	end
end

function SelectNextCarouselPlayer(direction)
	local count = 0
	local oldIndex = PlayerCarouselIndex
	while count < #PlayerCarousel do
		count = count + 1
		PlayerCarouselIndex = ClampCarouselIndex(PlayerCarouselIndex + direction)
		local player = PlayerCarousel[PlayerCarouselIndex]
		if player.Parent and player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				OnCaroselIndexChanged(PlayerCarouselIndex)
				return
			end
		end
	end
	PlayerCarouselIndex = oldIndex
end

function MovePlayerCarousel(direction)
	PlayerCarouselIndex = ClampCarouselIndex(PlayerCarouselIndex + direction)
	OnCaroselIndexChanged(PlayerCarouselIndex)
	ChangeSelectedPlayer(PlayerCarousel[PlayerCarouselIndex])
end

function GetPlayerPosition(player)
	if player.Character then
		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			return hrp.Position
		end
	end
end

function SwipeTweenOffScreen(direction)
	local endPosition = UDim2.new(1.5, 0, 1 - BOTTOM_SCREEN_PADDING_PERCENT, 0)
	if direction == -1 then
		endPosition = UDim2.new(-1.5, 0, 1 - BOTTOM_SCREEN_PADDING_PERCENT, 0)
	end

	local moveOutTween = TweenService:Create(ContextMenuFrame, SWIPE_MENU_AWAY_TWEEN, {["Position"] = endPosition})
	moveOutTween:Play()
	moveOutTween.Completed:wait()
end

function SwipeTweenOnScreen(direction)
	local startPosition = UDim2.new(-1.5, 0, 1 - BOTTOM_SCREEN_PADDING_PERCENT, 0)
	if direction == -1 then
		startPosition = UDim2.new(1.5, 0, 1 - BOTTOM_SCREEN_PADDING_PERCENT, 0)
	end
	ContextMenuFrame.Position = startPosition

	wait() -- UGLY HACK

	local moveInTween = TweenService:Create(ContextMenuFrame, SWIPE_MENU_IN_TWEEN, {["Position"] = UDim2.new(0.5, 0, 1 - BOTTOM_SCREEN_PADDING_PERCENT, 0)})
	moveInTween:Play()
	moveInTween.Completed:wait()
end

function DoSwipeCarouselMovement(direction)
	if DoingCarouselSwipe then
		return
	end
	DoingCarouselSwipe = true

	SwipeTweenOffScreen(direction)

	SelectNextCarouselPlayer(direction)
	ChangeSelectedPlayer(PlayerCarousel[PlayerCarouselIndex])

	SwipeTweenOnScreen(direction)

	DoingCarouselSwipe = false
end


function SetupSwipeToChangePlayer()
	TouchSwipeConnection = UserInputService.TouchSwipe:connect(function(swipeDirection, numberOfTouches, gameProcessedEvent)
		if not gameProcessedEvent then
			if swipeDirection == Enum.SwipeDirection.Right then
				DoSwipeCarouselMovement(-1)
			elseif swipeDirection == Enum.SwipeDirection.Left then
				DoSwipeCarouselMovement(1)
			end
		end
	end)
end

function BuildPlayerCarousel(selectedPlayer, worldPoint)
	PlayerCarousel = {selectedPlayer}
	PlayerCarouselIndex = 1
	local playersByProximity = {}
	local players = PlayerService:GetPlayers()
	for i = 1, #players do
		if players[i].UserId > 0 then
			if players[i] ~= selectedPlayer and players[i] ~= LocalPlayer then
				local playerPosition = GetPlayerPosition(players[i])
				if playerPosition then
					local distanceFromClicked = (worldPoint - playerPosition).magnitude
					table.insert(playersByProximity, {players[i], distanceFromClicked})
				end
			end
		end
	end

	local function closestPlayerComp(playerA, playerB)
		return playerA[2] < playerB[2]
	end
	table.sort(playersByProximity, closestPlayerComp)
	for i = 1, #playersByProximity do
		table.insert(PlayerCarousel, playersByProximity[i][1])
	end

	if #PlayerCarousel > 1 then
		ContextMenuFrame.RightArrowLabel.Visible = true
		ContextMenuFrame.LeftArrowLabel.Visible = true
		if UserInputService.TouchEnabled then
			SetupSwipeToChangePlayer()
		end
		OnCaroselIndexChanged(PlayerCarouselIndex)
	else
		ContextMenuFrame.RightArrowLabel.Visible = false
		ContextMenuFrame.LeftArrowLabel.Visible = false
	end
end

function OpenContextMenu(player, screenPoint, worldPoint)
	if ContextMenuOpening then
		return
	end

	ContextMenuOpen = true
	CameraManager:ContextMenuOpened()
	BuildPlayerCarousel(player, worldPoint)
	DisablePlayerMovement()
	BindMenuActions()
	SelectedPlayer = player
	ContextMenuItems:SetSelectedPlayer(player)
	Open2DMenu(player, screenPoint)
end


function DisconnectConnections()
	if TouchSwipeConnection then
		TouchSwipeConnection:Disconnect()
	end
end

function CloseContextMenu()
	UnBindContextActions()
	EnablePlayerMovement()
	DisconnectConnections()
	SelectedPlayer = nil
	ContextMenuFrame.Visible = false
	ContextMenuItems:ClearMenuItems()
	CameraManager:ContextMenuClosed()
	wait(CONTEXT_MENU_DEBOUNCE)
	ContextMenuOpen = false
end

function FindPlayerFromPart(part)
	if part and part.Parent then
		local possibleCharacter = part
		while possibleCharacter and not possibleCharacter:IsA("Model") do
			possibleCharacter = possibleCharacter.Parent
		end
		if possibleCharacter then
			return PlayerService:GetPlayerFromCharacter(possibleCharacter)
		end
	end
end

function CheckIfPointIsInSquare(checkPos, topLeft, bottomRight)
	return (topLeft.X <= checkPos.X and checkPos.X <= bottomRight.X and
		topLeft.Y <= checkPos.Y and checkPos.Y <= bottomRight.Y)
end

function ScreenPointInMenu(screenPoint)
	return CheckIfPointIsInSquare(screenPoint, ContextMenuFrame.AbsolutePosition, ContextMenuFrame.AbsolutePosition + ContextMenuFrame.AbsoluteSize)
end

function OnUserInput(screenPoint)
	if ContextMenuOpen and ScreenPointInMenu(screenPoint) then
		return
	end
	local camera = game.Workspace.CurrentCamera
	if camera then
		local ray = camera:ScreenPointToRay(screenPoint.X, screenPoint.Y)
		ray = Ray.new(ray.Origin, ray.Direction * MAX_CONTEXT_MENU_DISTANCE)
		local hitPart, hitPoint = game.Workspace:FindPartOnRay(ray, (not DEBUG_MODE) and LocalPlayer.Character or nil, false, true)
		local player = FindPlayerFromPart(hitPart)
		if player and (DEBUG_MODE or (player ~= LocalPlayer and player.UserId > 0)) then
			if player ~= SelectedPlayer then
				local screenPoint = camera:WorldToScreenPoint(hitPoint)
				OpenContextMenu(player, Vector2.new(screenPoint.X, screenPoint.Y), hitPoint)
			end
		end
	end
end

UserInputService.InputBegan:connect(function(inputObject, gameProcessedEvent)
	if not gameProcessedEvent then
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
			OnUserInput(Vector2.new(inputObject.Position.X, inputObject.Position.Y))
		end
	end
end)

UserInputService.TouchTap:connect(function(inputPositions, gameProcessedEvent)
	if not gameProcessedEvent then
		local averageTouchX = 0
		local averageTouchY = 0
		for i = 1, #inputPositions do
			averageTouchX = averageTouchX + inputPositions[i].X
			averageTouchY = averageTouchY + inputPositions[i].Y
		end
		averageTouchX = averageTouchX/#inputPositions
		averageTouchY = averageTouchY/#inputPositions
		OnUserInput(Vector2.new(averageTouchX, averageTouchY))
	end
end)
