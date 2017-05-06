--[[
	// FileName: ContextMenuItems.lua
	// Written by: TheGamer101
	// Description: Module for creating the context menu items for the menu and doing the actions when they are clicked.
]]

-- VARIABLES
LocalPlayer = PlayersService.LocalPlayer
while not LocalPlayer do
	PlayersService.PlayerAdded:wait()
	LocalPlayer = PlayersService.LocalPlayer
end

local ContextMenuItems = {}
ContextMenuItems.__index = ContextMenuItems

function ContextMenuItems.new()

end
