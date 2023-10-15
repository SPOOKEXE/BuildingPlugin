
plugin:Activate(false)

local pluginMouse = plugin:GetMouse()

local pluginModules = require(script.Parent.Modules)
local pluginWidgets = require(script.Parent.Widgets)

local pluginMaid = pluginModules.Maid.New()

-- // Setup // --
local toolbar = plugin:CreateToolbar('Building Suite')

pluginMaid:Give(pluginWidgets.Cleanup)

pluginMaid:Give(plugin.Deactivation:Connect(function()
	pluginMaid:Cleanup()
end))

pluginMaid:Give(plugin.Unloading:Connect(function()
	pluginMaid:Cleanup()
end))

pluginWidgets.Init( pluginMouse, toolbar )
pluginWidgets.Start( )
