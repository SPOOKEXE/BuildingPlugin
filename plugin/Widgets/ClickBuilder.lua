
local ChangeHistoryService= game:GetService('ChangeHistoryService')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local CollectionService = game:GetService('CollectionService')

local pluginModules = require(script.Parent.Parent.Modules)

local PluginKeybinds = pluginModules.Keybinds.Keybinds

local widgetMaid = pluginModules.Maid.New()
local buildMaid = pluginModules.Maid.New()
local gridMaid = pluginModules.Maid.New()

local SystemsContainer = nil :: table
local PluginMouse = nil :: PluginMouse
local PluginToolbar = nil :: PluginToolbar

local currentGridStud = 2
local concurrentWallHeight = 5
local concurrentWallThickness = 1

local concurrentWallPoints = {}
local concurrentFakeBalls = {}
local concurrentFakeWalls = {}

local baseWallSegment = Instance.new('Part')
baseWallSegment.Transparency = 0.6
baseWallSegment.Name = 'Segment'
baseWallSegment.Size = Vector3.one
baseWallSegment.Anchored = true
baseWallSegment.CastShadow = true
baseWallSegment.CanCollide = true
baseWallSegment.CanTouch = false
baseWallSegment.CanQuery = true
baseWallSegment.Massless = true

local baseBallVertex = Instance.new('Part')
baseBallVertex.Transparency = 0.6
baseBallVertex.Name = 'BallVertex'
baseBallVertex.Size = Vector3.one
baseBallVertex.Shape = Enum.PartType.Ball
baseBallVertex.Anchored = true
baseBallVertex.CastShadow = true
baseBallVertex.CanCollide = true
baseBallVertex.CanTouch = false
baseBallVertex.CanQuery = true
baseBallVertex.Massless = true

-- // Module // --
local Module = {}

function Module.LockToGrid( Position )
	return Vector3.new(
		math.round(Position.X * currentGridStud) / currentGridStud,
		Position.Y,
		math.round(Position.Z * currentGridStud) / currentGridStud
	)
end

function Module.SetGridStud( gridStud )
	currentGridStud = gridStud
end

function Module.EnableGrid()
	-- CollectionService:GetTagged()
	-- gridMaid:Give()
end

function Module.DisableGrid()
	gridMaid:Cleanup()
end

function Module.AdjustWallSegment( p0, p1, segment )
	local Distance = (p0 - p1).Magnitude
	segment.CFrame = CFrame.lookAt(p0, p1) * CFrame.new(0, 0, -Distance/2)
	segment.Size = Vector3.new(concurrentWallThickness, concurrentWallHeight, Distance)
end

function Module.ReconstructFakeConcurrentWall()
	-- concurrent wall parent
	local concurrentParent = workspace:FindFirstChild('ConcurrentWall')
	if not concurrentParent then
		concurrentParent = Instance.new('Folder')
		concurrentParent.Name = 'ConcurrentWall'
		concurrentParent.Parent = workspace
	end

	-- destroy extra unwanted walls
	while #concurrentFakeWalls > #concurrentWallPoints - 1 do
		local Item = table.remove(concurrentFakeWalls, #concurrentFakeWalls)
		if Item then
			Item:Destroy()
		end
	end

	-- destroy extra unwanted balls
	while #concurrentFakeBalls > #concurrentWallPoints do
		local Item = table.remove(concurrentFakeBalls, #concurrentFakeBalls)
		if Item then
			Item:Destroy()
		end
	end

	-- create necessary walls
	while #concurrentFakeWalls < #concurrentWallPoints - 1 do
		local cloneSegment = baseWallSegment:Clone()
		cloneSegment.Parent = concurrentParent
		table.insert( concurrentFakeWalls, cloneSegment )
	end

	-- create necessary vertex balls
	while #concurrentFakeBalls < #concurrentWallPoints do
		local cloneBall = baseBallVertex:Clone()
		cloneBall.Parent = concurrentParent
		table.insert( concurrentFakeBalls, cloneBall )
	end

	-- adjust walls
	local last = nil
	for index, point in ipairs( concurrentWallPoints ) do
		concurrentFakeBalls[index].Position = point
		if last then
			Module.AdjustWallSegment( last, point, concurrentFakeWalls[index-1] )
		end
		last = point
	end
end

function Module.CompleteConcurrentWall()
	-- completed concurrent wall
	local CompletedWallParent = workspace:FindFirstChild('CompletedWall')
	if not CompletedWallParent then
		CompletedWallParent = Instance.new('Folder')
		CompletedWallParent.Name = 'CompletedWall'
		CompletedWallParent.Parent = workspace
	end

	-- clone wall pieces
	for _, wallSegment in ipairs( concurrentFakeWalls ) do
		wallSegment.Transparency = 0
		wallSegment.Parent = CompletedWallParent
	end
	concurrentFakeWalls = { }
	concurrentWallPoints = { }

	-- clear fake vertex balls
	for _, ball in ipairs( concurrentFakeBalls ) do
		ball:Destroy()
	end
	concurrentFakeBalls = { }

	-- change history
	ChangeHistoryService:SetWaypoint('CompletedConcurrentWall')
end

function Module.ClearConcurrentWall()
	for _, wallSegment in ipairs( concurrentFakeWalls ) do
		wallSegment:Destroy()
	end
	for _, ball in ipairs( concurrentFakeBalls ) do
		ball:Destroy()
	end
	concurrentFakeBalls = { }
	concurrentFakeWalls = { }
	concurrentWallPoints = { }
	ChangeHistoryService:SetWaypoint('ClearConcurrentWall')
end

function Module.AdjustWallHeight( increment )
	concurrentWallHeight = math.max(concurrentWallHeight + increment, 0.25)
	print( concurrentWallHeight )
	Module.ReconstructFakeConcurrentWall()
	ChangeHistoryService:SetWaypoint('AdjustConcurrentWallHeight')
end

function Module.Append3DVertexPoint( position )
	position = Module.LockToGrid( position )
	table.insert(concurrentWallPoints, position )
	Module.ReconstructFakeConcurrentWall()
	ChangeHistoryService:SetWaypoint('AppendVertexConcurrentWall')
end

function Module.Pop3DVertexPoint( index )
	if index then
		table.remove(concurrentWallPoints, index )
	else
		table.remove(concurrentWallPoints, #concurrentWallPoints )
	end
	Module.ReconstructFakeConcurrentWall()
	ChangeHistoryService:SetWaypoint('PopVertexConcurrentWall')
end

function Module.EnableBuildMode()

	print('Enabled Build Mode.')

	Module.EnableGrid()

	-- pluginMouse.Hit
	-- pluginMouse.TargetSurface
	-- pluginMouse.Target
	-- pluginMouse.UnitRay

	buildMaid:Give(UserInputService.InputBegan:Connect(function(inputObject, wasProcessed)
		--[[if not wasProcessed then
			return
		end]]
		if PluginMouse and (not PluginMouse.Target) then
			return
		end

		if inputObject.KeyCode == PluginKeybinds.CLICK_BUILDER.APPEND_VERTEX then
			print('Append Vertex: ', PluginMouse.Hit.Position)
			Module.Append3DVertexPoint( PluginMouse.Hit.Position )
		elseif inputObject.KeyCode == PluginKeybinds.CLICK_BUILDER.POP_VERTEX then
			print('Pop Vertex')
			Module.Pop3DVertexPoint()
		elseif inputObject.KeyCode == PluginKeybinds.CLICK_BUILDER.COMPLETE_CONCURRENT_WALL then
			print('Complete Concurrent Wall')
			Module.CompleteConcurrentWall()
		elseif inputObject.KeyCode == PluginKeybinds.CLICK_BUILDER.INCREASE_WALL_HEIGHT then
			print('Increment Wall Height')
			Module.AdjustWallHeight( 0.25 )
		elseif inputObject.KeyCode == PluginKeybinds.CLICK_BUILDER.DECREASE_WALL_HEIGHT then
			print('Decrement Wall Height')
			Module.AdjustWallHeight( -0.25 )
		elseif inputObject.KeyCode == PluginKeybinds.CLICK_BUILDER.CLEAR_CONCURRENT_WALL then
			print('Clear Concurrent Wall')
			Module.ClearConcurrentWall()
		end

	end))
end

function Module.DisableBuildMode()
	print('Disable Build Mode.')
	Module.DisableGrid()
	Module.ClearConcurrentWall()
	local ConcurrentWallParent = workspace:FindFirstChild('ConcurrentWall')
	if ConcurrentWallParent then
		ConcurrentWallParent:Destroy()
	end
	buildMaid:Cleanup()
end

-- // Core // --
function Module.OpenWidget()

end

function Module.CloseWidget()
	Module.DisableBuildMode()
	Module.DisableGrid()
end

function Module.Init(otherSystems : table, mouse : PluginMouse, toolbar : PluginToolbar)

	SystemsContainer = otherSystems
	PluginMouse = mouse
	PluginToolbar = toolbar

	local isClickBuilderEnabled = false

	local clickBuilderButton = toolbar:CreateButton('Wall Builder', 'Enable/Disable the Wall Builder', 'rbxassetid://14453786895')
	clickBuilderButton.Enabled = true

	widgetMaid:Give(clickBuilderButton.Click:Connect(function()
		isClickBuilderEnabled = not isClickBuilderEnabled
		if isClickBuilderEnabled then
			Module.EnableBuildMode()
		else
			Module.DisableBuildMode()
		end
	end))
	widgetMaid:Give( clickBuilderButton )

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
