
local Module = {}

Module.Keybinds = {

	CLICK_BUILDER = {
		APPEND_VERTEX = Enum.KeyCode.One,
		POP_VERTEX = Enum.KeyCode.Two,
		COMPLETE_CONCURRENT_WALL = Enum.KeyCode.Three,
		CLEAR_CONCURRENT_WALL = Enum.KeyCode.Four,

		INCREASE_WALL_HEIGHT = Enum.KeyCode.Five,
		DECREASE_WALL_HEIGHT = Enum.KeyCode.Six,
	},

}

-- save to studio files
function Module:ToString()

end

-- load from studio files
function Module:FromString()

end

return Module
