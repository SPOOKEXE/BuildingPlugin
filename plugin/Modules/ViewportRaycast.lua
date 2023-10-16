
-- // Module // --
local Module = {}

function Module.RaycastFromScreenPoint( x, y, distance, rayparams )
	local CurrentCamera = workspace.CurrentCamera
	local viewportRay = CurrentCamera:ViewportPointToRay( x, y )
	return workspace:Raycast( viewportRay.Origin, viewportRay.Direction * distance, rayparams )
end

return Module
