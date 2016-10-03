--	// FileName: ChannelEchoMessage.lua
--	// Written by: TheGamer101
--	// Description: Create a message label for a standard message being echoed into another channel.

local MESSAGE_TYPE = "ChannelEchoMessage"

local clientChatModules = script.Parent.Parent
local ChatSettings = require(clientChatModules:WaitForChild("ChatSettings"))
local util = require(script.Parent:WaitForChild("Util"))

function CreateChannelEchoMessageLabel(messageData)
	local fromSpeaker = messageData.FromSpeaker
	local message = messageData.Message
	local echoChannel = messageData.OriginalChannel

	local extraData = messageData.ExtraData or {}
	local useFont = extraData.Font or Enum.Font.SourceSansBold
	local useFontSize = extraData.FontSize or ChatSettings.ChatWindowTextSize
	local useNameColor = extraData.NameColor or Color3.new(1, 1, 1)
	local useChatColor = extraData.ChatColor or Color3.new(1, 1, 1)

	local formatUseName = string.format("[%s]:", fromSpeaker)
	local formatChannelName = string.format("{%s}", echoChannel)

	local numNeededSpaces = util:GetNumberOfSpaces(formatUseName, useFont, useFontSize) + 1
	local numNeededSpaces2 = util:GetNumberOfSpaces(formatChannelName, useFont, useFontSize) + 1
	local numNeededUnderscore = util:GetNumberOfUnderscores(message, useFont, useFontSize)

	local tempMessage = string.rep(" ", numNeededSpaces2 + numNeededSpaces) .. string.rep("_", numNeededUnderscore)
	if messageData.IsFiltered then
 		tempMessage = string.rep(" ", numNeededSpaces2 + numNeededSpaces) .. messageData.Message
	end

	local BaseFrame, BaseMessage = util:CreateBaseMessage(tempMessage, useFont, useFontSize, useChatColor)
	local NameButton = util:AddNameButtonToBaseMessage(BaseMessage, useNameColor, formatUseName)
	local ChannelButton = util:AddChannelButtonToBaseMessage(BaseMessage, formatChannelName, useNameColor)

	NameButton.Position = UDim2.new(0, ChannelButton.Size.X.Offset + util:GetStringTextBounds(" ", useFont, useFontSize).X, 0, 0)

	local function UpdateTextFunction(newMessageObject)
		BaseMessage.Text = string.rep(" ", numNeededSpaces2 + numNeededSpaces) .. newMessageObject.Message
	end

	return {
		[util.KEY_BASE_FRAME] = BaseFrame,
		[util.KEY_BASE_MESSAGE] = BaseMessage,
		[util.KEY_UPDATE_TEXT_FUNC] = UpdateTextFunction
	}
end

return {
	[util.KEY_MESSAGE_TYPE] = MESSAGE_TYPE,
	[util.KEY_CREATOR_FUNCTION] = CreateChannelEchoMessageLabel
}
