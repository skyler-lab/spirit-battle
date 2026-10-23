-- ZoneConfig: the one place that says where the hub and zone rings are.
-- Edges[0] = edge of the safe hub. Edges[k] = outer edge of zone k. Distances are studs from Center.
local ZoneConfig = {}

ZoneConfig.Center = Vector3.new(0, 0, 0)
ZoneConfig.Edges = { [0] = 215, 315, 435, 575, 735, 925 }
ZoneConfig.HubFade = 30     -- sky fades in over this many studs after leaving the hub
ZoneConfig.BorderFade = 14  -- blend either side of a border between zones

local function smooth(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function ZoneConfig.Distance(pos)
	local c = ZoneConfig.Center
	return Vector2.new(pos.X - c.X, pos.Z - c.Z).Magnitude
end

-- 0 in the hub, 1-5 in zones, fractions while crossing a border (used for the storm fade).
function ZoneConfig.ZoneAt(pos)
	local d = ZoneConfig.Distance(pos)
	local E, hf, bf = ZoneConfig.Edges, ZoneConfig.HubFade, ZoneConfig.BorderFade
	if d <= E[0] then return 0 end
	if d < E[0] + hf then return smooth((d - E[0]) / hf) end
	for k = 1, 4 do
		if d < E[k] - bf then return k end
		if d < E[k] + bf then return k + smooth((d - (E[k] - bf)) / (2 * bf)) end
	end
	return 5
end

-- Whole number zone for game rules (drain, spawns). 0 = hub.
function ZoneConfig.WholeZone(pos)
	local d = ZoneConfig.Distance(pos)
	local E = ZoneConfig.Edges
	if d <= E[0] then return 0 end
	for k = 1, 5 do
		if d < E[k] then return k end
	end
	return 5
end

function ZoneConfig.InHub(pos)
	return ZoneConfig.Distance(pos) <= ZoneConfig.Edges[0]
end

return ZoneConfig
