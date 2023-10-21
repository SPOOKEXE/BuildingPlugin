
local UserInputService = game:GetService('UserInputService')

local pluginModules = require(script.Parent.Parent.Modules)

local PluginKeybinds = pluginModules.Keybinds.Keybinds

local widgetMaid = pluginModules.Maid.New()

local SystemsContainer = nil :: table
local PluginMouse = nil :: PluginMouse
local PluginToolbar = nil :: PluginToolbar

local PluginUIFolder = script.Parent.Parent.UI

local currentScreenUI : ScreenGui = nil
local currentCategoryIndex : number = nil
local categoryNames : table = nil
local categoryFrames : table = nil

local settingKeybindName = nil
local settingKeybindTable = nil
local settingKeybindFrame = nil

local IGNORE_KEY_ITEMS = { Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.KeyCode.Escape }
local BLACKLISTED_KEY_ITEMS = {  }

-- // Module // --
local Module = {}

function Module.DisableKeyCodeSetting()
	-- print('release keycode setting: ', settingKeybindName)
	if settingKeybindFrame then
		settingKeybindFrame.KeyCode:ReleaseFocus()
	end

	settingKeybindName = nil
	settingKeybindTable = nil
	settingKeybindFrame = nil
end

function Module.EnableKeyCodeSetting(keybindName, keybindTable, keybindFrame)
	settingKeybindName = keybindName
	settingKeybindTable = keybindTable
	settingKeybindFrame = keybindFrame
	-- print('enable keycode setting: ', keybindName)
end

function Module.ParseKeyCodeSetting( inputObject, _ )
	if settingKeybindName and settingKeybindTable and settingKeybindFrame then

		-- exit backup
		if inputObject.KeyCode == Enum.KeyCode.Escape then
			Module.DisableKeyCodeSetting()
			return
		end

		-- keycode/userinputtype to set to
		local enumItem : Enum.KeyCode | Enum.UserInputType = nil
		if inputObject.KeyCode ~= Enum.KeyCode.Unknown then
			enumItem = inputObject.KeyCode
		elseif inputObject.UserInputType ~= Enum.UserInputType.None then
			enumItem = inputObject.UserInputType
		end

		if table.find(IGNORE_KEY_ITEMS, enumItem) then
			return
		end

		-- blacklisted keycodes
		if table.find(BLACKLISTED_KEY_ITEMS, enumItem) then
			warn('cannot set it to this keycode - blacklisted keycode.')
			return
		end

		-- set if available
		if enumItem then
			-- print('Set Keybind ', settingKeybindName, ' to ', tostring(enumItem))
			settingKeybindTable[settingKeybindName] = enumItem
			settingKeybindFrame.KeyCode.PlaceholderText = tostring(enumItem)
			-- disable keybind setting
			Module.DisableKeyCodeSetting()
		end
	end
end

function Module.UpdateKeybindLabels()

	local KeybindsScroll = currentScreenUI.Frame.Bottom.Keybinds.Scroll
	local counter = 1

	for category, keybindTable in pairs( PluginKeybinds ) do

		-- category divider
		local categoryDivider = KeybindsScroll:FindFirstChild(category)
		if not categoryDivider then
			categoryDivider = PluginUIFolder.TemplateCategoryDivider:Clone()
			categoryDivider.Name = category
			categoryDivider.Title.Text = string.upper(category)
			categoryDivider.LayoutOrder = counter
			categoryDivider.Parent = KeybindsScroll
		end
		counter += 1

		-- each keycode value
		for keybindName, keybindEnum in pairs( keybindTable ) do

			local Frame = KeybindsScroll:FindFirstChild(keybindName)
			if not Frame then
				Frame = PluginUIFolder.TemplateKeybind:Clone()
				Frame.Name = keybindName
				Frame.Title.Text = string.upper(keybindName)
				Frame.KeyCode.PlaceholderText = tostring(keybindEnum)
				Frame.LayoutOrder = counter
				Frame.Parent = KeybindsScroll

				local KeyCodeTextBox = Frame.KeyCode :: TextBox

				local frameMaid = pluginModules.Maid.New()

				frameMaid:Give( KeyCodeTextBox.Focused:Connect(function()
					-- print('focused')
					Module.EnableKeyCodeSetting(keybindName, keybindTable, Frame)
				end) )

				frameMaid:Give( KeyCodeTextBox.FocusLost:Connect(function()
					-- print('focus lost')
					Module.DisableKeyCodeSetting()
				end) )

				widgetMaid:Give(frameMaid)
			end

			counter += 1
		end
	end

end

function Module.UpdatePropertyLabels()

	-- PluginUIFolder.TemplateProperty:Clone()

end

function Module.UpdateCurrent()
	if currentCategoryIndex == 1 then
		Module.UpdateKeybindLabels()
	elseif currentCategoryIndex == 2 then
		Module.UpdatePropertyLabels()
	end
end

function Module.IncrementCategory( increment : number )
	currentCategoryIndex += math.sign(increment) -- prevents any number except -1, 0, 1.

	if currentCategoryIndex > #categoryNames then
		currentCategoryIndex = 1
	elseif currentCategoryIndex < 1 then
		currentCategoryIndex = #categoryNames
	end

	currentScreenUI.Frame.Top.Title.Text = categoryNames[currentCategoryIndex]
	for index, frame in ipairs( categoryFrames ) do
		frame.Visible = (index==currentCategoryIndex)
	end

	Module.DisableKeyCodeSetting()
	Module.UpdateCurrent()
end

-- // Core // --
function Module.OpenWidget()

	currentScreenUI = PluginUIFolder.PluginUI:Clone()
	currentScreenUI.Parent = game:GetService('CoreGui')
	widgetMaid:Give( currentScreenUI )

	currentCategoryIndex = 1
	categoryNames = { }
	categoryFrames = { }

	for _, Frame in ipairs( currentScreenUI.Frame.Bottom:GetChildren() ) do
		if Frame:IsA("Frame") then
			table.insert(categoryNames, Frame.Name)
			table.insert(categoryFrames, Frame)
		end
	end

	widgetMaid:Give(currentScreenUI.Frame.Top.Left.Activated:Connect(function()
		Module.IncrementCategory( 1 )
	end))

	widgetMaid:Give(currentScreenUI.Frame.Top.Right.Activated:Connect(function()
		Module.IncrementCategory( -1 )
	end))

	Module.UpdateCurrent()
end

function Module.CloseWidget()
	Module.DisableKeyCodeSetting()
	widgetMaid:Cleanup()
end

function Module.Init(otherSystems : table, mouse : PluginMouse, toolbar : PluginToolbar)
	SystemsContainer = otherSystems
	PluginMouse = mouse
	PluginToolbar = toolbar

	local isUIWidgetOpen = false

	local clickBuilderButton = toolbar:CreateButton('Configuration', 'Builder Settings', 'rbxassetid://14453786895')
	clickBuilderButton.Enabled = true

	widgetMaid:Give(clickBuilderButton.Click:Connect(function()
		isUIWidgetOpen = not isUIWidgetOpen
		if isUIWidgetOpen then
			Module.OpenWidget()
		else
			Module.CloseWidget()
		end
	end))
	widgetMaid:Give( clickBuilderButton )

	widgetMaid:Give(UserInputService.InputBegan:Connect(Module.ParseKeyCodeSetting))
end

function Module.Start()

end

function Module.Cleanup()
	SystemsContainer = nil
	PluginMouse = nil
	PluginToolbar = nil

	Module.CloseWidget()
	widgetMaid:Cleanup()
end

return Module
