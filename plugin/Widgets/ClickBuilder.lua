
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
local currentYLock = nil
local concurrentWallHeight = 5
local concurrentWallThickness = 1
local resizeAlignEnabled = true
local currentHoverPosition = Vector3.zero

local concurrentWallPoints = {}
local concurrentFakeBalls = {}
local concurrentFakeWalls = {}

local CurrentCamera = workspace.CurrentCamera

local gridLevelPart = Instance.new('Part')
gridLevelPart.Name = 'GridLevel'
gridLevelPart.Transparency = 1
gridLevelPart.Anchored = true
gridLevelPart.CanCollide = false
gridLevelPart.CanQuery = false
gridLevelPart.CanTouch = false
gridLevelPart.CastShadow = false
gridLevelPart.Massless = true
gridLevelPart.Position = Vector3.zero
gridLevelPart.Size = Vector3.new(1024, 1, 1024)
local gridTexture = Instance.new('Texture')
gridTexture.Name = 'Grid'
gridTexture.Color3 = Color3.new(1, 0, 0)
gridTexture.Face = Enum.NormalId.Top
gridTexture.Texture = 'rbxassetid://2045685837'
gridTexture.Parent = gridLevelPart
gridLevelPart.Parent = script

local baseWallSegment = Instance.new('Part')
baseWallSegment.TopSurface = Enum.SurfaceType.Smooth
baseWallSegment.BottomSurface = Enum.SurfaceType.Smooth
baseWallSegment.Transparency = 0.6
baseWallSegment.Name = 'Segment'
baseWallSegment.Size = Vector3.one
baseWallSegment.Anchored = true
baseWallSegment.CastShadow = true
baseWallSegment.CanCollide = true
baseWallSegment.CanTouch = false
baseWallSegment.CanQuery = true
baseWallSegment.Massless = true
baseWallSegment.Parent = script

local baseBallVertex = Instance.new('Part')
baseBallVertex.Transparency = 0.6
baseBallVertex.Name = 'BallVertex'
baseBallVertex.Size = Vector3.one
baseBallVertex.Shape = Enum.PartType.Ball
baseBallVertex.TopSurface = Enum.SurfaceType.Smooth
baseBallVertex.BottomSurface = Enum.SurfaceType.Smooth
baseBallVertex.Anchored = true
baseBallVertex.CastShadow = true
baseBallVertex.CanCollide = true
baseBallVertex.CanTouch = false
baseBallVertex.CanQuery = true
baseBallVertex.Massless = true
baseBallVertex.Parent = script

local buildCylinderPost = Instance.new('Part')
buildCylinderPost.Transparency = 0.6
buildCylinderPost.Name = 'CylinderPost'
buildCylinderPost.Size = Vector3.one
buildCylinderPost.Shape = Enum.PartType.Cylinder
buildCylinderPost.TopSurface = Enum.SurfaceType.Smooth
buildCylinderPost.BottomSurface = Enum.SurfaceType.Smooth
buildCylinderPost.Anchored = true
buildCylinderPost.CastShadow = true
buildCylinderPost.CanCollide = false
buildCylinderPost.CanTouch = false
buildCylinderPost.CanQuery = false
buildCylinderPost.Massless = true
buildCylinderPost.Parent = script
local buildWallPost = Instance.new('Part')
buildWallPost.Transparency = 0.6
buildWallPost.Name = 'WallSegment'
buildWallPost.TopSurface = Enum.SurfaceType.Smooth
buildWallPost.BottomSurface = Enum.SurfaceType.Smooth
buildWallPost.Size = Vector3.one
buildWallPost.Anchored = true
buildWallPost.CastShadow = true
buildWallPost.CanCollide = false
buildWallPost.CanTouch = false
buildWallPost.CanQuery = false
buildWallPost.Massless = true
buildWallPost.Parent = script

local function SnapToGrid( Position, GridStep )
	return Vector3.new(
		math.round(Position.X / GridStep) * GridStep,
		Position.Y,
		math.round(Position.Z / GridStep) * GridStep
	)
end

local function IsInputItemDown( inputItem : Enum.KeyCode | Enum.UserInputType )
	local IsDown = false
	pcall(function()
		if UserInputService:IsKeyDown( inputItem ) then
			IsDown = true
		end
	end)
	pcall(function()
		if UserInputService:IsMouseButtonPressed( inputItem ) then
			IsDown = true
		end
	end)
	return IsDown
end

-- // Module // --
local Module = {}

function Module.SetGridStud( gridStud )
	currentGridStud = math.clamp(gridStud, 0.5, 12)
	print('New Grid Size: ', currentGridStud)
	gridTexture.StudsPerTileU = (6 * currentGridStud)
	gridTexture.StudsPerTileV = (gridTexture.StudsPerTileU)
end

function Module.EnableGrid()
	local Folder = workspace:FindFirstChild('ConcurrentWall')

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true

	gridLevelPart.Parent = workspace

	gridMaid:Give(RunService.Heartbeat:Connect(function()
		raycastParams.FilterDescendantsInstances = { buildCylinderPost, buildWallPost, gridLevelPart, Folder }
		local raycastResult = pluginModules.ViewportRaycast.RaycastFromScreenPoint( PluginMouse.X, PluginMouse.Y, 300, raycastParams )
		if raycastResult then
			gridLevelPart.Position = SnapToGrid(raycastResult.Position, 32)
		else
			gridLevelPart.Position = SnapToGrid(CurrentCamera.CFrame.Position, 32)
		end
		if currentYLock then
			gridLevelPart.Position = Vector3.new( gridLevelPart.Position.X, currentYLock, gridLevelPart.Position.Z )
		end
	end))

end

function Module.DisableGrid()
	gridLevelPart.Parent = script
	gridMaid:Cleanup()
end

function Module.AdjustWallSegment( p0, p1, segment )
	local Distance = (p0 - p1).Magnitude
	segment.CFrame = CFrame.lookAt(p0, p1) * CFrame.new( 0, concurrentWallHeight / 2, -Distance/2)
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
	while #concurrentFakeWalls > math.max(#concurrentWallPoints - 1, 0) do
		local Item = table.remove(concurrentFakeWalls, #concurrentFakeWalls)
		if Item then
			Item:Destroy()
		end
	end

	-- destroy extra unwanted balls
	while #concurrentFakeBalls > math.max(#concurrentWallPoints, 0) do
		local Item = table.remove(concurrentFakeBalls, #concurrentFakeBalls)
		if Item then
			Item:Destroy()
		end
	end

	-- create necessary walls
	while #concurrentFakeWalls < math.max(#concurrentWallPoints - 1, 0) do
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
	local lastPoint = nil
	local lastWall = nil
	for index, point in ipairs( concurrentWallPoints ) do
		concurrentFakeBalls[index].Position = point
		if lastPoint then
			local currentWall = concurrentFakeWalls[index-1]
			Module.AdjustWallSegment( lastPoint, point, currentWall )
			if lastWall and resizeAlignEnabled then
				pluginModules.ResizeAlign(
					{ Object = lastWall, Normal = Enum.NormalId.Front },
					{ Object = currentWall, Normal = Enum.NormalId.Back }
				)
			end
			lastWall = currentWall
		end
		lastPoint = point
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
	position = SnapToGrid( position, currentGridStud )
	if currentYLock then
		position = Vector3.new( position.X, currentYLock, position.Z )
	end
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

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true

	buildCylinderPost.Parent = workspace

	buildMaid:Give(RunService.Heartbeat:Connect(function()
		buildCylinderPost.Size = Vector3.new(concurrentWallHeight, 1, 1 )

		local Folder = workspace:FindFirstChild('ConcurrentWall')
		raycastParams.FilterDescendantsInstances = { buildCylinderPost, buildWallPost, Folder }
		if not currentYLock then
			table.insert(raycastParams.FilterDescendantsInstances, gridLevelPart)
		end

		local raycastResult = nil
		if PluginMouse and PluginMouse.Target and table.find( concurrentFakeBalls, PluginMouse.Target ) then
			raycastResult = { Instance = PluginMouse.Target, Position = PluginMouse.Target.Position }
		elseif PluginMouse and PluginMouse.Target and table.find( concurrentFakeWalls, PluginMouse.Target ) then
			raycastResult = { Instance = PluginMouse.Target, Position = PluginMouse.Hit.Position }
		else
			raycastResult = pluginModules.ViewportRaycast.RaycastFromScreenPoint( PluginMouse.X, PluginMouse.Y, 300, raycastParams )
		end

		buildWallPost.Parent = (#concurrentWallPoints > 0 and raycastResult) and workspace or script
		if not raycastResult then
			return
		end

		local rayPositionGridLocked = SnapToGrid(raycastResult.Position, currentGridStud)
		if currentYLock then
			rayPositionGridLocked = Vector3.new(rayPositionGridLocked.X, currentYLock, rayPositionGridLocked.Z)
		end

		currentHoverPosition = rayPositionGridLocked

		buildCylinderPost.CFrame = CFrame.new( rayPositionGridLocked ) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.new( buildCylinderPost.Size.X / 2, 0, 0 )
		if #concurrentWallPoints > 0 then
			Module.AdjustWallSegment( concurrentWallPoints[#concurrentWallPoints], rayPositionGridLocked, buildWallPost )
		end
	end))

	buildMaid:Give(UserInputService.InputBegan:Connect(function(_, _)
		if PluginMouse and (not PluginMouse.Target) then
			return
		end

		local Folder = workspace:FindFirstChild('ConcurrentWall')
		raycastParams.FilterDescendantsInstances = { buildCylinderPost, buildWallPost, gridLevelPart, Folder }
		local raycastResult = pluginModules.ViewportRaycast.RaycastFromScreenPoint( PluginMouse.X, PluginMouse.Y, 300, raycastParams )

		if IsInputItemDown(PluginKeybinds.CLICK_BUILDER.APPEND_VERTEX) then
			if currentHoverPosition then
				Module.Append3DVertexPoint( currentHoverPosition )
			end
		elseif IsInputItemDown(PluginKeybinds.CLICK_BUILDER.POP_VERTEX) then
			print('Pop Vertex')
			Module.Pop3DVertexPoint()
		elseif IsInputItemDown(PluginKeybinds.CLICK_BUILDER.COMPLETE_CONCURRENT_WALL) then
			print('Complete Concurrent Wall')
			Module.CompleteConcurrentWall()
		elseif IsInputItemDown(PluginKeybinds.CLICK_BUILDER.INCREASE_WALL_HEIGHT) then
			print('Increment Wall Height')
			Module.AdjustWallHeight( 0.25 )
		elseif IsInputItemDown(PluginKeybinds.CLICK_BUILDER.DECREASE_WALL_HEIGHT) then
			print('Decrement Wall Height')
			Module.AdjustWallHeight( -0.25 )
		elseif IsInputItemDown(PluginKeybinds.CLICK_BUILDER.CLEAR_CONCURRENT_WALL) then
			print('Clear Concurrent Wall')
			Module.ClearConcurrentWall()
		elseif IsInputItemDown(PluginKeybinds.CLICK_BUILDER.INCREASE_GRID_SIZE) then
			Module.SetGridStud( currentGridStud + 0.5 )
		elseif IsInputItemDown(PluginKeybinds.CLICK_BUILDER.DECREASE_GRID_SIZE) then
			Module.SetGridStud( currentGridStud - 0.5 )
		elseif IsInputItemDown(PluginKeybinds.CLICK_BUILDER.TOGGLE_Y_HEIGHT) then
			if currentYLock then
				currentYLock = nil
			else
				currentYLock = raycastResult and math.floor(raycastResult.Position.Y) or 5
			end
		elseif IsInputItemDown(PluginKeybinds.CLICK_BUILDER.INCREASE_Y_HEIGHT) then
			if currentYLock then
				currentYLock += 0.5
			end
		elseif IsInputItemDown(PluginKeybinds.CLICK_BUILDER.DECREASE_Y_HEIGHT) then
			if currentYLock then
				currentYLock -= 0.5
			end
		elseif IsInputItemDown( PluginKeybinds.CLICK_BUILDER.TOGGLE_RESIZE_ALIGN ) then
			resizeAlignEnabled = not resizeAlignEnabled
			print('Resize Alignment Enabled: ', resizeAlignEnabled)
		end

	end))
end

function Module.DisableBuildMode()
	print('Disable Build Mode.')
	Module.DisableGrid()
	Module.ClearConcurrentWall()
	buildWallPost.Parent = script
	buildCylinderPost.Parent = script
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

	Module.SetGridStud( 0.5 )

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
