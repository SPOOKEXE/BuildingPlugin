
local Module = {}

Module.Keybinds = {

	CLICK_BUILDER = {
		APPEND_VERTEX = Enum.KeyCode.One,
		POP_VERTEX = Enum.KeyCode.Two,
		COMPLETE_CONCURRENT_WALL = Enum.KeyCode.Three,
		CLEAR_CONCURRENT_WALL = Enum.KeyCode.Four,

		INCREASE_WALL_HEIGHT = Enum.KeyCode.Y,
		DECREASE_WALL_HEIGHT = Enum.KeyCode.U,
		INCREASE_GRID_SIZE = Enum.KeyCode.I,
		DECREASE_GRID_SIZE = Enum.KeyCode.O,

		TOGGLE_Y_HEIGHT = Enum.KeyCode.H,
		INCREASE_Y_HEIGHT = Enum.KeyCode.J,
		DECREASE_Y_HEIGHT = Enum.KeyCode.K,
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
