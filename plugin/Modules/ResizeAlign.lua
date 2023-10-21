
--[[
	Dumbed down version of ResizeAlign just for SQUARE/RECTANGULAR parts.
	- Outer Touch
	- No Wedge Support

	(sourced from sleitnick ResizeAlign, edited by SPOOK_EXE.)
]]

export type Face = { Object: BasePart, Normal: Enum.NormalId }

local function otherNormals(dir: Vector3)
	if math.abs(dir.X) > 0 then
		return Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)
	elseif math.abs(dir.Y) > 0 then
		return Vector3.new(1, 0, 0), Vector3.new(0, 0, 1)
	else
		return Vector3.new(1, 0, 0), Vector3.new(0, 1, 0)
	end
end

local function getFacePoints(face: Face)
	local hsize = face.Object.Size / 2
	local cf = face.Object.CFrame

	local faceDir = Vector3.FromNormalId(face.Normal)
	local faceA, faceB = otherNormals(faceDir)
	faceDir, faceA, faceB = faceDir*hsize, faceA*hsize, faceB*hsize

	return {
		cf:PointToWorldSpace(faceDir + faceA + faceB);
		cf:PointToWorldSpace(faceDir + faceA - faceB);
		cf:PointToWorldSpace(faceDir - faceA - faceB);
		cf:PointToWorldSpace(faceDir - faceA + faceB);
	}

end

local function getNormal(face: Face)
	return face.Object.CFrame:VectorToWorldSpace(Vector3.FromNormalId(face.Normal))
end

local function getDimension(face: Face)
	local dir = Vector3.FromNormalId(face.Normal)
	return Vector3.new(math.abs(dir.X), math.abs(dir.Y), math.abs(dir.Z))
end

local function getBasis(face: Face)
	local hsize = face.Object.Size / 2
	local faceDir = Vector3.FromNormalId(face.Normal)
	local faceNormal = face.Object.CFrame:VectorToWorldSpace(faceDir)
	local facePoint = face.Object.CFrame:PointToWorldSpace(faceDir * hsize)
	return facePoint, faceNormal
end

-- Get the point in the list most "out" of the face
local function getPositivePointToFace(face, points: {Vector3}): Vector3
	local basePoint, normal = getBasis(face)
	local maxDist = -math.huge
	local maxPoint = nil
	for _, point in points do
		local dist = (point - basePoint):Dot(normal)
		if dist > maxDist then
			maxDist = dist
			maxPoint = point
		end
	end
	return maxPoint
end

local function resizePart(face: Face, delta: number)
	-- Extend existing part
	local axis = Vector3.FromNormalId(face.Normal)
	face.Object.Size += Vector3.new(math.abs(axis.X), math.abs(axis.Y), math.abs(axis.Z)) * delta
	face.Object.CFrame *= CFrame.new(axis * (delta / 2))
end

-- Calculate the result
local function doExtend(faceA : Face, faceB : Face)
	local pointsA = getFacePoints(faceA)
	local pointsB = getFacePoints(faceB)
	local localDimensionA = getDimension(faceA)
	local localDimensionB = getDimension(faceB)
	local dirA = getNormal(faceA)
	local dirB = getNormal(faceB)

	-- Compare the directions
	local a, b, c = dirA:Dot(dirA), dirA:Dot(dirB), dirB:Dot(dirB)
	local denom = a*c - b*b
	local isParallel = math.abs(denom) < 0.001

	-- Find the points to extend out to meet
	local extendPointA, extendPointB = getPositivePointToFace(faceB, pointsA), getPositivePointToFace(faceA, pointsB)

	-- Find the closest distance between the rays (extendPointA, dirA) and (extendPointB, dirB):
	-- See: http://geomalgorithms.com/a07-_distance.html#dist3D_Segment_to_Segment
	local startSep = extendPointB - extendPointA
	local d, e = dirA:Dot(startSep), dirB:Dot(startSep)

	-- Is this a degenerate case?
	if isParallel then
		-- Parts are parallel, extend faceA to faceB
		local lenA = (extendPointA - extendPointB):Dot(getNormal(faceB))

		local extendableA = (localDimensionA * faceA.Object.Size).magnitude
		if getNormal(faceA):Dot(getNormal(faceB)) > 0 then
			lenA = -lenA
		end
		if lenA < -extendableA then
			return
		end

		resizePart(faceA, lenA)
		return
	end

	-- Get the distances to extend by
	local lenA = -(b*e - c*d) / denom
	local lenB = -(a*e - b*d) / denom

	-- Are both extents doable?
	-- Note: Negative amounts to extend by *are* allowed, but only
	-- up to the size of the part on the dimension being extended on.
	local extendableA = (localDimensionA * faceA.Object.Size).magnitude
	local extendableB = (localDimensionB * faceB.Object.Size).magnitude
	if lenA < -extendableA then
		return
	end
	if lenB < -extendableB then
		return
	end

	-- Both are doable, execute:
	resizePart(faceA, lenA)
	resizePart(faceB, lenB)
end

return doExtend