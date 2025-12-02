-- name: \\#FF8800\\Colored\\#00FF00\\Nametags\\#FF00FF\\ v1.0
-- description: Disable Nametags setting if you use this mod

local HudMeasureText = djui_hud_measure_text
local HudPrintTextInterpolated = djui_hud_print_text_interpolated
local HudSetColor = djui_hud_set_color
local HudSetFont = djui_hud_set_font
local HudSetResolution = djui_hud_set_resolution
local HudWorldPosToScreenPos = djui_hud_world_pos_to_screen_pos
local IsPlayerActive = is_player_active
local NetworkPlayerGetPaletteColor = network_player_get_palette_color
local Vec3fDist = vec3f_dist

local _lastTags = {}

local function HandlePlayer(m)
	local out = { x = 0, y = 0, z = 0 }
	local pos = { x = m.marioObj.header.gfx.pos.x, y = m.pos.y + 200, z = m.marioObj.header.gfx.pos.z }
	local np = gNetworkPlayers[m.playerIndex]
	local dist = Vec3fDist(gLakituState.pos, m.pos)
	if not IsPlayerActive(m) or dist > 5000 or
		not HudWorldPosToScreenPos(pos, out) or
		m.marioBodyState.updateTorsoTime ~= gMarioStates[0].marioBodyState.updateTorsoTime or
		np.currCourseNum ~= gNetworkPlayers[0].currCourseNum or
		np.currActNum ~= gNetworkPlayers[0].currActNum or
		np.currLevelNum ~= gNetworkPlayers[0].currLevelNum or
		np.currAreaIndex ~= gNetworkPlayers[0].currAreaIndex
	then
		return
	end
	-- prepare name
	local scale = 0.04 + 150 / dist
	local name = np.name
	local nameList = {}
	local nameCount = 0
	local color = NetworkPlayerGetPaletteColor(np, CAP)
	local tmpColor = ""
	local tmpCount = 0
	local sumWidth = 0
	for i = 1, #name do
		local c = name:sub(i,i)
		if c == '\\' then
			inSlash = not inSlash
			tmpColor = ""
			tmpCount = 0
		elseif inSlash and c ~= '#' then
			tmpColor = tmpColor .. c
			tmpCount = tmpCount + 1
			if tmpCount == 2 then
				color.r = tonumber(tmpColor, 16)
				tmpColor = ""
			elseif tmpCount == 4 then
				color.g = tonumber(tmpColor, 16)
				tmpColor = ""
			elseif tmpCount == 6 then
				color.b = tonumber(tmpColor, 16)
				tmpColor = ""
			end
		elseif not inSlash then
			nameList[nameCount] =
			{
				t = c,
				c = { r = color.r, g = color.g, b = color.b },
				l = HudMeasureText(c) * scale
			}
			sumWidth = sumWidth + nameList[nameCount].l
			nameCount = nameCount + 1
		end
	end
	-- print name
	local last = _lastTags[m.playerIndex]
	if last == nil then
		last = { x = out.x, y = out.y }
	end
	local xOffset = - sumWidth / 2
	for i = 0, (nameCount - 1) do
		HudSetColor(nameList[i].c.r, nameList[i].c.g, nameList[i].c.b, 255)
		HudPrintTextInterpolated(nameList[i].t, last.x + xOffset, last.y, scale, out.x + xOffset, out.y, scale)
		xOffset = xOffset + nameList[i].l
	end
	_lastTags[m.playerIndex] = { x = out.x, y = out.y }
end

local function OnHudRender()
	HudSetResolution(RESOLUTION_N64)
	HudSetFont(FONT_MENU)
	for i = 1, (MAX_PLAYERS - 1) do
		local m = gMarioStates[i]
		HandlePlayer(m)
	end
end

hook_event(HOOK_ON_HUD_RENDER, OnHudRender)
