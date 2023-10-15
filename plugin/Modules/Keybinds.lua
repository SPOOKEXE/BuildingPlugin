
local Module = {}

Module.Keybinds = {

	CLICK_BUILDER = {
		APPEND_VERTEX = Enum.KeyCode.One,
		POP_VERTEX = Enum.KeyCode.Two,
		COMPLETE_CONCURRENT_WALL = Enum.KeyCode.Three,
		CLEAR_CONCURRENT_WALL = Enum.KeyCode.Four,

		INCREASE_WALL_HEIGHT = Enum.KeyCode.Five,
		DECREASE_WALL_HEIGHT = Enum.KeyCode.Six,
		INCREASE_GRID_SIZE = Enum.KeyCode.Seven,
		DECREASE_GRID_SIZE = Enum.KeyCode.Eight,
	},

}

-- save to studio files
function Module:KeybindsToString()
	return '{}'
end

-- load from studio files
function Module:KeybindsFromString( keybindsString )

end

return Module
