
local Module = {}

Module.Keybinds = {

	CLICK_BUILDER = {
		APPEND_VERTEX = Enum.KeyCode.One,
		POP_VERTEX = Enum.KeyCode.Two,
		COMPLETE_CONCURRENT_WALL = Enum.KeyCode.Three,
		CLEAR_CONCURRENT_WALL = Enum.KeyCode.Four,

		INCREASE_WALL_HEIGHT = Enum.KeyCode.Y,
		DECREASE_WALL_HEIGHT = Enum.KeyCode.U,
		INCREASE_GRID_SIZE = Enum.KeyCode.B,
		DECREASE_GRID_SIZE = Enum.KeyCode.N,

		TOGGLE_Y_HEIGHT = Enum.KeyCode.H,
		INCREASE_Y_HEIGHT = Enum.KeyCode.J,
		DECREASE_Y_HEIGHT = Enum.KeyCode.K,

		TOGGLE_RESIZE_ALIGN = Enum.KeyCode.V,
	},

}

-- TODO: SetKeybind and save to studio settings instead of SaveToStudio() function.

-- save to studio
function Module.SaveToStudio()
	for category, keybindTable in pairs( Module.Keybinds ) do
		for keybindName, keybindEnum in pairs( keybindTable ) do
			local indexName = category..'_'..keybindName
			plugin:SetSetting(indexName, tostring(keybindEnum))
		end
	end
end

-- load from studio
function Module.LoadFromStudio()

	for category, keybindTable in pairs( Module.Keybinds ) do
		for keybindName, _ in pairs( keybindTable ) do
			local indexName = category..'_'..keybindName
			local savedValue = plugin:GetSetting(indexName)
			if not savedValue then
				continue
			end

			local enumPath = Enum
			for _, pathIndex in ipairs( string.split(savedValue, '.') ) do
				enumPath = enumPath[pathIndex]
				if not enumPath then
					break
				end
			end

			if enumPath then
				keybindTable[keybindName] = enumPath
			end
		end
	end

end

return Module
