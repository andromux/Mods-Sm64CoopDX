local ipairs, obj_field, chat_cmd, chat_msg, get_model_id, storage_exists, storage_save, storage_load, scale_obj, set_billboard, mark_delete, vec_len, hook_bhv, hook_ev, discord_id, spwn_sobj, clamp, OBJ_FLAG_SET_FACE_ANGLE_TO_MOVE_ANGLE, OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE, coop_id, global_from_local = ipairs, define_custom_obj_fields, hook_chat_command, djui_chat_message_create, smlua_model_util_get_id, mod_storage_exists, mod_storage_save, mod_storage_load, cur_obj_scale, obj_set_billboard, obj_mark_for_deletion, vec3f_length, hook_behavior, hook_event, network_discord_id_from_local_index, spawn_sync_object, clamp, OBJ_FLAG_SET_FACE_ANGLE_TO_MOVE_ANGLE, OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE, get_coopnet_id, network_global_index_from_local
local FONT_HUD, FONT_NORMAL = 2, 0

if gGlobalSyncTable == nil then
    gGlobalSyncTable = {}
end
if gGlobalSyncTable.authorized_ids == nil then
    gGlobalSyncTable.authorized_ids = {}
end


local function is_authorized(m)
    return true
end

if gGlobalSyncTable.tagVisible == nil then gGlobalSyncTable.tagVisible = {} end

if _G.OmmApi then
    log_to_console("[SPARKLIES] OMM API detected RETIRED64 Youtube version")
else
    log_to_console("[SPARKLIES] OMM API not detected RETIRED64 Youtube")
end

local OmmApi = _G.OmmApi or nil
local has_omm = OmmApi ~= nil

local SPIN_POUND_REGISTERED = false
local function try_register_omm_spin_pound()
    if SPIN_POUND_REGISTERED then return end
    if _G.OmmApi ~= nil and _G.OmmApi.ACT_OMM_SPIN_POUND_LAND ~= nil then
        OmmApi = _G.OmmApi
        has_omm = true
        SPIN_POUND_REGISTERED = true
    end
end

hook_event(HOOK_UPDATE, function()
    try_register_omm_spin_pound()
end)

local SOUND_OPEN  = 1879113601
local SOUND_CLOSE = 1881341825
local SOUND_NAV   = 1879113601

offset_v2_enabled = false
dance_wave_enabled = true
local dance_wave_spawned = false

local COLOR_LIST = { "Pink", "Green", "Red", "Blue", "Gold", "Purple", "ogexcrystal" }

local RAINBOW_ENABLED = false

if storage_exists("rb-sp") then
    RAINBOW_ENABLED = storage_load("rb-sp") == "true"
else
    storage_save("rb-sp", "false")
end

local EX_RB_LIST = { "exnebula", "expinkgold", "excrystal", "exred", "expurple", "exgreen" }

local EX_RAINBOW_ENABLED = false

if storage_exists("exrb-sp") then
    EX_RAINBOW_ENABLED = storage_load("exrb-sp") == "true"
else
    storage_save("exrb-sp", "false")
end

local MODEL_MAP = {
    pink        = get_model_id("pink_sparkly"),
    green       = get_model_id("green_sparkly"),
    red         = get_model_id("red_sparkly"),
    blue        = get_model_id("blue_sparkly"),
    gold        = get_model_id("gold_sparkly"),
    purple      = get_model_id("purple_sparkly"),
    black       = get_model_id("black_sparkly"),
    white       = get_model_id("white_sparkly"),
    exgreen  = get_model_id("ExGreen_sparkly"),
    expurple = get_model_id("ExPurple_sparkly"),
    exred     = get_model_id("ExRed_sparkly"),
    excrystal  = get_model_id("ExCrystal_sparkly"),
    exnebula   = get_model_id("ExNebula_sparkly"),
    expinkgold = get_model_id("ExPinkgold_sparkly"),
    ogexcrystal = get_model_id("ogexcrystal_sparkly") 
}

local DEFAULT_SPARKLIE_LT = 30
local EXP_SPARKLIE_LT = 80

local str_to_bool = {
  ["true"] = true,
  ["false"] = false
}

local models = {}
for _, color in ipairs({
  "pink",
  "green",
  "red",
  "blue",
  "gold",
  "purple",
  "black",
  "white",
  "ExCrystal",
  "ExNebula",
  "ExPinkgold",
  "ExRed",
  "ExPurple",
  "ExGreen",
  "ogexcrystal"
}) do
  models[color] = get_model_id(color .. "_sparkly")
end

local saved_color = storage_exists("color") and storage_load("color") or "pink"

saved_color = string.lower(saved_color)

if not models[saved_color] then
    saved_color = "pink"
    storage_save("color", "pink")
end

local current_model = models[saved_color]

local function get_sparkly_model()
    if EX_RAINBOW_ENABLED then
        local pick = EX_RB_LIST[math.random(1, #EX_RB_LIST)]
        return MODEL_MAP[pick]
    end

    if RAINBOW_ENABLED then
        local rand = COLOR_LIST[math.random(1, #COLOR_LIST)]
        return MODEL_MAP[rand:lower()]
    end

    return current_model
end

gp_effect_enabled = true
if storage_exists("gp_effect") then
    gp_effect_enabled = storage_load("gp_effect") == "true"
else
    storage_save("gp_effect", "true")
end

local offset_v2_enabled = false

if storage_exists("sp-offset_v2") then
    offset_v2_enabled = storage_load("sp-offset_v2") == "true"
else
    storage_save("sp-offset_v2", "false")
end

local got_star, SPARKLIES_LIFE_TIME, SPARKLIES_SPEED, active_sparkles, particle_timers, sparklies_enabled = false, 50, 1, 0, {}, true
local ACT_OMM_STAR_DANCE = 1073746688
local ACT_GRAND_STAR_GRAB = 6409


local function aura_setup(o, isRoll)
    o.oFaceAngleYaw = math.random(-32768, 32767)
    o.oMoveAngleYaw = math.random(0, 65536)
    o.oTimer = SPARKLIES_LIFE_TIME + 10

    local v0 = (math.random() - 0.5) * 10
    local v1 = (math.random() - 0.5) * 10
    local v2 = (math.random() - 0.5) * 10
    o.oVelX, o.oVelY, o.oVelZ = v0 * SPARKLIES_SPEED, v1 * SPARKLIES_SPEED, v2 * SPARKLIES_SPEED

    local v3 = math.sqrt(v0 * v0 + v1 * v1 + v2 * v2)
    if v3 ~= 0 then
        local yOffset = 30
        if isRoll then
            yOffset = 60
        end

        local posMultiplier = 30

        if offset_v2_enabled then
            posMultiplier = 50
            yOffset = 50
            if isRoll then
                yOffset = 65
            end
        end

        o.oPosX = o.oPosX + posMultiplier * v0 / v3
        o.oPosY = o.oPosY + yOffset * v1 / v3
        o.oPosZ = o.oPosZ + posMultiplier * v2 / v3
    end
end

local function aura_init(o)
  o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE + OBJ_FLAG_SET_FACE_ANGLE_TO_MOVE_ANGLE + OBJ_FLAG_ACTIVE_FROM_AFAR
  o.oAnimState = 0
  o.oScale = math.random(7, 11) / 16   
  scale_obj(o.oScale)
  o.oFriction = 0
end

local function aura_loop(o)
    set_billboard(o)
    o.oPosX = o.oPosX + o.oVelX
    o.oPosY = o.oPosY + o.oVelY
    o.oPosZ = o.oPosZ + o.oVelZ

    o.oAnimState = o.oAnimState + 1
    o.oTimer = o.oTimer - 2

    if o.oTimer <= 0 then
        active_sparkles = active_sparkles - 1
        mark_delete(o)
        return
    end
  
    if o.oTimer > 10 then
        o.oScale = o.oScale - 0.004
    else
        o.oScale = o.oScale + 0.000 * (1 - o.oTimer / 10)
    end

    scale_obj(o.oScale)
end

-- CORRECCIÓN: Definición única de id_bhvAura
local id_bhvAura = hook_bhv(nil, OBJ_LIST_UNIMPORTANT, true, aura_init, aura_loop)

local command_functions = {
  on = function()
    sparklies_enabled = true
    return true
  end,
  off = function()
    sparklies_enabled = false
    return true
  end,
  color = function(color)
    if models[color] then
      current_model = models[color]
      storage_save("color", color)
    else
      chat_msg("available colors: pink, green, red, blue, gold, purple, black, white, ogexcrystal")
    end
    return true
  end,
  give = function(arg1, arg2)
    local id, bool = tonumber(arg1), str_to_bool[arg2]
    local m = gMarioStates[0]
    if id and bool ~= nil then
        local target_gid = tostring(network_global_index_from_local(id))
        local self_gid = tostring(network_global_index_from_local(m.playerIndex))

        if target_gid == self_gid then
            chat_msg("\\#ffff00\\you cannot give/remove sparklies to yourself")
            return true
        end

        if gGlobalSyncTable.authorized_ids == nil then
            gGlobalSyncTable.authorized_ids = {}
        end

        gGlobalSyncTable.authorized_ids[target_gid] = bool
        chat_msg((bool and "gave" or "removed") .. " sparklies to player #" .. id)
        return true
    end

    chat_msg("Usage: /sparklies give \\#62ffff\\[localIndex] [true|false]")
    return true
  end
}

hook_ev(HOOK_MARIO_UPDATE, function(m)
  if m.playerIndex ~= 0 or not sparklies_enabled then
    return
  end

  if gp_effect_enabled then
    local is_gp = false

    if m.action == ACT_GROUND_POUND_LAND then
        is_gp = true
    end

    if not is_gp and has_omm and OmmApi and OmmApi.ACT_OMM_SPIN_POUND_LAND and m.action == OmmApi.ACT_OMM_SPIN_POUND_LAND then
        is_gp = true
    end

   if not is_gp and has_omm and OmmApi and OmmApi.ACT_OMM_WATER_GROUND_POUND_LAND
   and m.action == OmmApi.ACT_OMM_WATER_GROUND_POUND_LAND then
    is_gp = true
    end

    if is_gp then
        local burstAmount = 15
        local spawnY = m.pos.y + 20
        for i = 1, burstAmount do
            active_sparkles = active_sparkles + 1
            spwn_sobj(id_bhvAura, get_sparkly_model(), m.pos.x, spawnY, m.pos.z, function(o)
                local oldSpeed, oldLife = SPARKLIES_SPEED, SPARKLIES_LIFE_TIME
                SPARKLIES_SPEED = 1.8
                SPARKLIES_LIFE_TIME = 20
                aura_setup(o, false)
                SPARKLIES_SPEED = oldSpeed
                SPARKLIES_LIFE_TIME = oldLife
                o.oScale = 1.6    
            end)
        end
    end
  end

  local MAX_SPARKLIES
  if has_omm and (m.action == OmmApi.ACT_OMM_ROLL or m.action == OmmApi.ACT_OMM_ROLL_AIR) then
      MAX_SPARKLIES = 31
  else
      MAX_SPARKLIES = 72     
  end

  local speed = vec_len(m.vel)

  local isRoll = false
  if has_omm then
      local rollActs = {
          OmmApi.ACT_OMM_ROLL,
          OmmApi.ACT_OMM_ROLL_AIR
      }

      for _, act in ipairs(rollActs) do
          if m.action == act then
              isRoll = true
              break
          end
      end
  end

  local divisor = 30
  local clampMax = 2

  if isRoll then
      divisor = 25
      clampMax = 2
  elseif m.action == ACT_WALKING or m.action == ACT_RUNNING then
      clampMax = 0
  end

  local timer_threshold
  if speed < 1 then
      timer_threshold = 4
  else
      timer_threshold = 3 - math.floor(clamp(speed / divisor, 0, clampMax))
  end

  SPARKLIES_SPEED = 1
  SPARKLIES_LIFE_TIME = DEFAULT_SPARKLIE_LT
  if not particle_timers[m.playerIndex] then
    particle_timers[m.playerIndex] = 0
  end

  particle_timers[m.playerIndex] = particle_timers[m.playerIndex] + 1
  if MAX_SPARKLIES <= active_sparkles then
    return
  end

  if timer_threshold <= particle_timers[m.playerIndex] then
    particle_timers[m.playerIndex] = 0
    active_sparkles = active_sparkles + 1

    local baseOffset = 55
    local spawnY = m.pos.y + baseOffset

    local isRoll = false

    if has_omm then
        local rollActs = {
            OmmApi.ACT_OMM_ROLL,
            OmmApi.ACT_OMM_ROLL_AIR
        }

        local rainbowSpin = OmmApi.ACT_OMM_RAINBOW_SPIN

        local function isInAction(actionList)
            for _, act in ipairs(actionList) do
                if m.action == act then
                    return true
                end
            end
            return false
        end

        if m.action == rainbowSpin then
            spawnY = spawnY + 45
        else
            if offset_v2_enabled then
                spawnY = spawnY + 30
            elseif isInAction(rollActs) then
                spawnY = spawnY + 60
                isRoll = true        
            end
        end
    end

    if not (has_omm and m.action == OmmApi.ACT_OMM_RAINBOW_SPIN) then
        if m.vel and m.vel.y and m.vel.y < 0 then
            local fallSpeed = -m.vel.y
            local extra = math.floor(fallSpeed * 2)
            extra = math.min(40, extra)
            local fallOffset = 40 + extra
            baseOffset = math.max(baseOffset, fallOffset)
            spawnY = m.pos.y + baseOffset
        end
    end

    if m.action == ACT_GRAND_STAR_GRAB or m.action == ACT_STAR_DANCE or m.action == ACT_OMM_STAR_DANCE then
        spawnY = m.pos.y + 70
    elseif vec_len(m.vel) < 1 and not isRoll and not isJump then
        spawnY = m.pos.y + 60
    end

    local ACT_BOWSER_KEY_GRAB = 4866
    if dance_wave_enabled and (m.action == ACT_STAR_DANCE_EXIT or m.action == ACT_STAR_DANCE_NO_EXIT or m.action == ACT_STAR_DANCE_WATER or m.action == ACT_GRAND_STAR_GRAB or m.action == ACT_STAR_DANCE or m.action == ACT_OMM_STAR_DANCE or m.action == ACT_BOWSER_KEY_GRAB) then
        if not dance_wave_spawned then
            local waveAmount = 80
            local waveSpeed = 3
            local waveLife = EXP_SPARKLIE_LT
            local waveScale = 1.5

            for _ = 1, waveAmount do
                spwn_sobj(id_bhvAura, get_sparkly_model(), m.pos.x, spawnY, m.pos.z, function(o)
                    local oldSpeed, oldLife = SPARKLIES_SPEED, SPARKLIES_LIFE_TIME
                    SPARKLIES_SPEED = waveSpeed
                    SPARKLIES_LIFE_TIME = waveLife
                    aura_setup(o, isRoll)
                    SPARKLIES_SPEED = oldSpeed
                    SPARKLIES_LIFE_TIME = oldLife
                    o.oScale = waveScale
                end)
            end

            dance_wave_spawned = true
        end
    else
        dance_wave_spawned = false
    end

    local NORMAL_AMOUNT = 1
    for i = 1, NORMAL_AMOUNT do
        spwn_sobj(id_bhvAura, get_sparkly_model(), m.pos.x, spawnY, m.pos.z, function(o)
            local oldLife = SPARKLIES_LIFE_TIME

            if (speed < 1 and not isJump)
                or isRoll
                or m.action == ACT_STAR_DANCE
                or m.action == ACT_STAR_DANCE_EXIT
                or m.action == ACT_STAR_DANCE_NO_EXIT
                or m.action == ACT_STAR_DANCE_WATER
                or m.action == ACT_GRAND_STAR_GRAB
                or m.action == ACT_OMM_STAR_DANCE
                or m.action == ACT_BOWSER_KEY_GRAB then
                SPARKLIES_LIFE_TIME = 22
            else
                SPARKLIES_LIFE_TIME = DEFAULT_SPARKLIE_LT
            end

            aura_setup(o, isRoll)
            SPARKLIES_LIFE_TIME = oldLife
        end)
    end
  end
end)

hook_ev(HOOK_ON_WARP, function()
  active_sparkles = 0
end)

hook_ev(HOOK_MARIO_UPDATE, function(m)
    if m.playerIndex ~= 0 then return end

    if active_sparkles > 30 then
        active_sparkles = math.max(0, active_sparkles - 1)
    end

    if m.pos.x > 5000 or m.pos.z > 5000 or m.pos.x < -5000 or m.pos.z < -5000 then
        active_sparkles = 0
    end
end)

obj_field({oScale = "f32"})

chat_cmd("sparklies", "\\#62ffff\\[on|off|color|give]", function(msg)
    local m = gMarioStates[0]  
    local args, cmd = {}, msg:lower():gmatch("%S+")
    for a in cmd, nil, nil do
        table.insert(args, a)
    end

    local command = args[1]
    local fn = command_functions[command]
    if fn then
        return fn(args[2], args[3])
    end

    chat_msg("Usage: /sparklies \\#62ffff\\[on|off|color|give]")
    return true
end)


local function draw_text_shadow(txt, x, y, scale, r, g, b, a)
    djui_hud_set_color(0, 0, 0, 180)
    djui_hud_print_text(txt, x + 3, y + 3, scale)
    djui_hud_set_color(r, g, b, a)
    djui_hud_print_text(txt, x, y, scale)
end


sp_menu = {
    open = false,
    selected = 1,
    colors = { "pink", "green", "red", "blue", "gold", "purple", "black", "white",
        "ExCrystal", "ExNebula", "ExPinkgold", "ExRed", "ExGreen", "ExPurple", "ogexcrystal" },

    color_index = 1,
    move_cooldown = 0
}

sp_menu.options = {
    "Sparklies",
    "Change Color",
    "Extra Effects >"
}

sp_menu.submenu_open = false
sp_menu.sub_selected = 1

sp_menu.extra_effects = {
    "Star Effects",
    "G-Pound Effect",
    "Sp-Offset V2",
    "Rainbow Mode",
    "ExRainbow Mode"
}

sp_menu.scroll = 0          
sp_menu.max_visible = 6

if storage_exists("star_effects") then
    dance_wave_enabled = storage_load("star_effects") == "true"
else
    dance_wave_enabled = true
    storage_save("star_effects", "true")
end

local saved_color = storage_load("color")
if saved_color then
    for i, c in ipairs(sp_menu.colors) do
        if c == saved_color then
            sp_menu.color_index = i
            break
        end
    end
end

if _G.HOOK_ON_HUD_RENDER == nil then _G.HOOK_ON_HUD_RENDER = 19 end
if _G.HOOK_MARIO_UPDATE == nil then _G.HOOK_MARIO_UPDATE = 1 end


hook_event(HOOK_MARIO_UPDATE, function(m)
    m.freeze = sp_menu.open and 1 or 0
end)


hook_event(HOOK_ON_HUD_RENDER, function()
    if not sp_menu.open then return end

    local w, h = djui_hud_get_screen_width(), djui_hud_get_screen_height()

    djui_hud_set_color(0, 0, 0, 160)
    djui_hud_render_rect(0, 0, w, h)

    djui_hud_set_font(FONT_HUD)


    draw_text_shadow(
        sp_menu.submenu_open and "EXTRA EFFECTS" or "SPARKLIES MENU",
        w * 0.35, 40, 3,
        255, 255, 255, 255
    )

    djui_hud_set_font(FONT_NORMAL)

    local baseY = 120


    if not sp_menu.submenu_open then
        for i = 1, #sp_menu.options do
            local opt = sp_menu.options[i]
            local selected = (i == sp_menu.selected)


            local r = 255
            local g = selected and 255 or 255
            local b = selected and 0 or 255


            local value = ""
            if opt == "Sparklies" then
                value = sparklies_enabled and "ON" or "OFF"
            elseif opt == "Change Color" then
                value = sp_menu.colors[sp_menu.color_index]
            end

            local y = baseY + ((i - 1) * 90)

            draw_text_shadow(opt,   w * 0.25, y, 2, r, g, b, 255)
            draw_text_shadow(value, w * 0.65, y, 2, r, g, b, 255)
        end


    else
        for i = 1, #sp_menu.extra_effects do
            local opt = sp_menu.extra_effects[i]
            local selected = (i == sp_menu.sub_selected)

            local r = 255
            local g = selected and 255 or 255
            local b = selected and 0 or 255

            local value = ""
            if opt == "Star Effects" then
                value = dance_wave_enabled and "ON" or "OFF"
            elseif opt == "G-Pound Effect" then
                value = gp_effect_enabled and "ON" or "OFF"
            elseif opt == "Sp-Offset V2" then
                value = offset_v2_enabled and "ON" or "OFF"
            elseif opt == "Rainbow Mode" then
                value = RAINBOW_ENABLED and "ON" or "OFF"
            elseif opt == "ExRainbow Mode" then
                value = EX_RAINBOW_ENABLED and "ON" or "OFF"
            end

            local y = baseY + ((i - 1) * 90)

            draw_text_shadow(opt,   w * 0.25, y, 2, r, g, b, 255)
            draw_text_shadow(value, w * 0.65, y, 2, r, g, b, 255)
        end
    end


    djui_hud_set_font(FONT_HUD)
    draw_text_shadow("press B to close / back", w * 0.25, h - 48, 1.7, 200, 200, 200, 255)
end)


hook_event(HOOK_ON_HUD_RENDER, function()
    if not sp_menu.open then return end

    local m = gMarioStates[0]
    local pad = m.controller

    sp_menu.move_cooldown = sp_menu.move_cooldown - 1
    if sp_menu.move_cooldown > 0 then return end

    local moved = false


    if pad.buttonPressed & B_BUTTON ~= 0 then
        if sp_menu.submenu_open then
            sp_menu.submenu_open = false
            play_sound(SOUND_CLOSE, gGlobalSoundSource)
            return
        end

        sp_menu.open = false
        play_sound(SOUND_CLOSE, gGlobalSoundSource)
        return
    end

    if not sp_menu.submenu_open then
        
        if pad.rawStickY > 60 then
            sp_menu.selected = sp_menu.selected - 1
            if sp_menu.selected < 1 then sp_menu.selected = #sp_menu.options end
            play_sound(SOUND_NAV, gGlobalSoundSource)
            moved = true

        elseif pad.rawStickY < -60 then
            sp_menu.selected = sp_menu.selected + 1
            if sp_menu.selected > #sp_menu.options then sp_menu.selected = 1 end
            play_sound(SOUND_NAV, gGlobalSoundSource)
            moved = true
        end

        local sel = sp_menu.options[sp_menu.selected]


        if sel == "Change Color" then

            if pad.rawStickX < -60 then
                sp_menu.color_index = sp_menu.color_index - 1
                if sp_menu.color_index < 1 then sp_menu.color_index = #sp_menu.colors end

                current_model = models[sp_menu.colors[sp_menu.color_index]]
                storage_save("color", sp_menu.colors[sp_menu.color_index])

                play_sound(SOUND_NAV, gGlobalSoundSource)
                moved = true

            elseif pad.rawStickX > 60 then
                sp_menu.color_index = sp_menu.color_index + 1
                if sp_menu.color_index > #sp_menu.colors then sp_menu.color_index = 1 end

                current_model = models[sp_menu.colors[sp_menu.color_index]]
                storage_save("color", sp_menu.colors[sp_menu.color_index])

                play_sound(SOUND_NAV, gGlobalSoundSource)
                moved = true
            end
        end


        if pad.buttonPressed & A_BUTTON ~= 0 then
            play_sound(SOUND_NAV, gGlobalSoundSource)

            if sel == "Sparklies" then
                sparklies_enabled = not sparklies_enabled

            elseif sel == "Change Color" then
                sp_menu.color_index = sp_menu.color_index + 1
                if sp_menu.color_index > #sp_menu.colors then sp_menu.color_index = 1 end

                current_model = models[sp_menu.colors[sp_menu.color_index]]
                storage_save("color", sp_menu.colors[sp_menu.color_index])

            elseif sel == "Extra Effects >" then
                sp_menu.submenu_open = true
                return
            end
        end


    else
        if pad.rawStickY > 60 then
            sp_menu.sub_selected = sp_menu.sub_selected - 1
            if sp_menu.sub_selected < 1 then sp_menu.sub_selected = #sp_menu.extra_effects end
            play_sound(SOUND_NAV, gGlobalSoundSource)
            moved = true

        elseif pad.rawStickY < -60 then
            sp_menu.sub_selected = sp_menu.sub_selected + 1
            if sp_menu.sub_selected > #sp_menu.extra_effects then sp_menu.sub_selected = 1 end
            play_sound(SOUND_NAV, gGlobalSoundSource)
            moved = true
        end

        if pad.buttonPressed & A_BUTTON ~= 0 then
            local opt = sp_menu.extra_effects[sp_menu.sub_selected]
            play_sound(SOUND_NAV, gGlobalSoundSource)

            if opt == "Star Effects" then
                dance_wave_enabled = not dance_wave_enabled
                storage_save("star_effects", tostring(dance_wave_enabled))

            elseif opt == "G-Pound Effect" then
                gp_effect_enabled = not gp_effect_enabled
                storage_save("gp_effect", tostring(gp_effect_enabled))

            elseif opt == "Sp-Offset V2" then
                offset_v2_enabled = not offset_v2_enabled
                storage_save("sp-offset_v2", tostring(offset_v2_enabled))

            elseif opt == "Rainbow Mode" then
                RAINBOW_ENABLED = not RAINBOW_ENABLED
                storage_save("rb-sp", RAINBOW_ENABLED and "true" or "false")

            elseif opt == "ExRainbow Mode" then
                EX_RAINBOW_ENABLED = not EX_RAINBOW_ENABLED
                storage_save("exrb-sp", EX_RAINBOW_ENABLED and "true" or "false")
            end
        end
    end

    if moved then
        sp_menu.move_cooldown = 8
    end
end)


chat_cmd("sp", "- Open sparklies menu", function(msg)
    sp_menu.open = true
    play_sound(SOUND_OPEN, gGlobalSoundSource)
    return true
end)