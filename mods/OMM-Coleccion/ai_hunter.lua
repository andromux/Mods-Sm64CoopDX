-- name: AI hunter (Single Player)
-- description: This is a mod where a player becomes a hunter controlled by an AI!\nTo activate this mod you can either connect to yourself or have a friend connect to you and they don't do anything <-- this is the more stable option because connecting to yourself could make the bot lag and teleport if the window hasn't been active much, just make sure the hunters window has been active for at least 10 seconds, otherwise Have Fun! \nMod made by \\#0000ff\\Blocky \n\n\\#ff0000\\ !THIS IS A SINGLEPLAYER MOD!

local host = network_local_index_from_global(0)

local skip_actions = {
    [ACT_WATER_PUNCH] = true,
    [ACT_JUMP_KICK] = true,
    [ACT_GROUND_POUND] = true,
    [ACT_BACKWARD_AIR_KB] = true,
    [ACT_FORWARD_AIR_KB] = true,
    [ACT_BACKWARD_GROUND_KB] = true,
    [ACT_SWIMMING_END - 1] = true,
    [ACT_DISAPPEARED] = true,
    [ACT_END_PEACH_CUTSCENE] = true,
    [ACT_WALL_KICK_AIR] = true,
    [ACT_JUMP] = true,
    [ACT_DOUBLE_JUMP] = true,
    [ACT_TRIPLE_JUMP] = true,
    [ACT_JUMP_LAND] = true,
    [ACT_DOUBLE_JUMP_LAND] = true,
    [ACT_TRIPLE_JUMP_LAND] = true,
    [ACT_PULLING_DOOR] = true,
    [ACT_PUSHING_DOOR] = true,
    [ACT_LAVA_BOOST] = true,
    [ACT_BUTT_SLIDE] = true,
    [ACT_FORWARD_GROUND_KB] = true
}

local unhittable_actions = {
    [ACT_HOLDING_BOWSER] = true,
    [ACT_RELEASING_BOWSER] = true,
    [ACT_PICKING_UP_BOWSER] = true,
    [ACT_READING_NPC_DIALOG] = true,
    [ACT_WAITING_FOR_DIALOG] = true,
    [ACT_PULLING_DOOR] = true,
    [ACT_PUSHING_DOOR] = true,
    [ACT_READING_AUTOMATIC_DIALOG] = true,
    [ACT_FIRST_PERSON] = true
}

local function respawn(m, o, timer)
    m.pos.x, m.pos.y, m.pos.z = o.oPosX, o.oPosY + 300, o.oPosZ
    m.invincTimer = timer
end

---@param m MarioState
local function mario_update(m)
    if network_is_server() or m.playerIndex ~= 0 or network_player_connected_count() < 2 then return end

    local np = gNetworkPlayers[0]


    if np.currLevelNum ~= gNetworkPlayers[host].currLevelNum or np.currAreaIndex ~= gNetworkPlayers[host].currAreaIndex or np.currActNum ~= gNetworkPlayers[host].currActNum then
        warp_to_level(gNetworkPlayers[host].currLevelNum, gNetworkPlayers[host].currAreaIndex,
            gNetworkPlayers[host].currActNum)
    end

    local action = m.action

    local o = gMarioStates[host].marioObj

    if o == nil then
        return
    end

    --m.controller.buttonPressed = ~m.controller.buttonPressed
    --m.controller.stickMag = 0

    m.health = 0x880

    if m.floor.type == SURFACE_BURNING and m.pos.y == m.floorHeight then
        set_mario_action(m, ACT_LAVA_BOOST, 0)
    end

    if skip_actions[action] and m.wall == nil then
        return
    end

    local y1 = 0
    local y2 = 0
    local z = 0
    local x = 0
    local angle = 0

    x = m.pos.x - o.oPosX
    z = m.pos.z - o.oPosZ
    x = math.sqrt(x * x + z * z)
    y1 = -o.oPosY
    y2 = -m.pos.y
    angle = -atan2s(x, y2 - y1)
    m.faceAngle.x = angle * -1
    m.faceAngle.y = obj_angle_to_object(m.marioObj, o)

    if action == ACT_HOLDING_POLE then
        force_idle_state(m)
        respawn(m, o, 30)
    end

    if (m.floor ~= nil and m.floor.type >= SURFACE_PAINTING_WARP_D3 and m.floor.type <= SURFACE_PAINTING_WARP_FC) then
        m.floor.type =
            SURFACE_DEFAULT
    end
    if m.wall ~= nil then
        if dist_between_objects(m.marioObj, o) > 600 then --dist_between_objects(m.marioObj, o) > 350 then
            set_mario_action(m, ACT_WALL_KICK_AIR, 0)
            m.forwardVel = 55
            m.vel.y = 40
        elseif dist_between_objects(m.marioObj, o) > 350 and m.pos.y <= m.floorHeight then
            set_mario_action(m, ACT_JUMP, 0)
            m.forwardVel = 55
            m.vel.y = 45
        elseif action == ACT_BUTT_SLIDE then
            m.floor.type = SURFACE_VERY_SLIPPERY
            set_mario_action(m, ACT_JUMP, 0)
            apply_slope_accel(m)
            m.vel.y = 45
        end
    elseif action == ACT_JUMP_LAND then
        if m.forwardVel <= 45 then
            set_mario_action(m, ACT_DOUBLE_JUMP, 0)
            m.forwardVel = 45
            m.vel.y = 55
        end
    elseif action == ACT_DOUBLE_JUMP_LAND then
        if m.forwardVel <= 45 then
            set_mario_action(m, ACT_TRIPLE_JUMP, 0)
            m.forwardVel = 45
        end
    elseif action == ACT_TRIPLE_JUMP_LAND then
        if m.forwardVel <= 45 then
            set_mario_action(m, ACT_DIVE, 0)
            m.forwardVel = 45
        end
    elseif action == ACT_DIVE then
        m.forwardVel = 50
    elseif action == ACT_FORWARD_ROLLOUT then
        m.forwardVel = 45
    elseif m.forwardVel <= 10 and m.flags == m.flags | MARIO_WING_CAP then
        m.forwardVel = 20
    elseif action == ACT_BUTT_SLIDE then
        apply_slope_accel(m)
        execute_mario_action(m.marioObj)
        execute_mario_action(m.marioObj)
    elseif action == ACT_LAVA_BOOST then
        m.forwardVel = 30
    elseif not (action & ACT_GROUP_MASK) == ACT_GROUP_SUBMERGED or m.pos.y == m.floorHeight then
        if m.forwardVel <= 20 then
            set_mario_action(m, ACT_LONG_JUMP, 0)
            m.forwardVel = 50
            m.vel.y = 25
        elseif gMarioStates[host].pos.y == gMarioStates[host].floorHeight and m.floorHeight - gMarioStates[host].floorHeight <= -400 and m.pos.y == m.floorHeight and m.forwardVel <= 20 then
            set_mario_action(m, ACT_JUMP, 0)
            m.forwardVel = 55
            m.vel.y = 45
        elseif action == ACT_LONG_JUMP_LAND then
            set_mario_action(m, ACT_HOLD_JUMP, 0)
            m.vel.y = 50
            m.forwardVel = 52
            set_mario_action(m, ACT_DIVE, 0)
        elseif action == ACT_DIVE_SLIDE then
            set_mario_action(m, ACT_FORWARD_ROLLOUT, 0)
        elseif m.forwardVel <= 50 and m.forwardVel >= 45 then
            set_mario_action(m, ACT_JUMP_KICK, 0)
            m.forwardVel = 50
            m.vel.y = 25
        elseif action == ACT_JUMP_LAND then
            set_mario_action(m, ACT_DIVE, 0)
        end
    end

    if gMarioStates[host].action == ACT_PUSHING_DOOR or gMarioStates[host].action == ACT_PULLING_DOOR then
        respawn(m, gMarioStates[host].marioObj, 120)
    end

    if gMarioStates[host].pos.y == gMarioStates[host].floorHeight and m.floorHeight - gMarioStates[host].floorHeight <= -400 and m.pos.y == m.floorHeight then
        set_mario_action(m, ACT_JUMP, 0)
        m.forwardVel = 55
        m.vel.y = 45
    end

    if action == ACT_WATER_IDLE or action == ACT_SWIMMING_END then
        set_mario_action(m, ACT_SWIMMING_END - 1, 0)
        m.forwardVel = 15
    elseif dist_between_objects(m.marioObj, o) >= 3000 or action == ACT_HOLDING_POLE then
        respawn(m, o, 120)
    end

    if dist_between_objects(m.marioObj, o) <= 350 and m.flags ~= m.flags | MARIO_WING_CAP and not unhittable_actions[gMarioStates[host].action] then
        if (action & ACT_GROUP_MASK) == ACT_GROUP_SUBMERGED then
            set_mario_action(m, ACT_WATER_PUNCH, 0)
        elseif dist_between_objects(m.marioObj, o) <= 250 and m.pos.y == m.floorHeight then
            set_mario_action(m, ACT_JUMP_KICK, 0)
        elseif dist_between_objects(m.marioObj, o) <= 200 then
            set_mario_action(m, ACT_GROUND_POUND, 0)
        end
    end
end

if not network_is_server then
    hook_event(HOOK_USE_ACT_SELECT, function() return false end)
end

hook_event(HOOK_MARIO_UPDATE, mario_update)

-- i know this is not an actual AI and that is poorly coded,
-- i wasn't planning on releasing this anyways, i'll probably make something with actual Pathfinding
-- and not just turn towards the player and such since i don't personally think this qualifies as an AI
-- at all, i might have an idea to make an actual one but it will lack romhack compatibility unless we get
-- more things to work with in future (talking about functions for the lua API)
-- anyways i should probably get working on the actual AI so keep an eye out for that
-- it'll be wayy better than this piece of garbage!

-- Blocky
