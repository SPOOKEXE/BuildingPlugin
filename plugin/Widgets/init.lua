
local cachedModules = {}
for _, ModuleScript in ipairs( script:GetChildren() ) do
	cachedModules[ModuleScript.Name] = require(ModuleScript)
end

-- // Module // --
local Module = {}

function Module.Init( pluginMouse, pluginToolbar )

	-- init modules
	for moduleName, module in pairs( cachedModules ) do
		local SystemsContainer = {}
		for otherName, otherModule in pairs( cachedModules ) do
			if moduleName == otherName then
				continue
			end
			SystemsContainer[otherName] = otherModule
		end
		module.Init( SystemsContainer, pluginMouse, pluginToolbar )
	end

end

function Module.Start( )

	for _, module in pairs( cachedModules ) do
		module.Start()
	end

end

function Module.Cleanup( )
	for _, module in pairs( cachedModules ) do
		module.Cleanup( )
	end
end

return Module
