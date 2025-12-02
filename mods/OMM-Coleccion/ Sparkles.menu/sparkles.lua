local COLOR_MODELS = {    
    ["pink"] = smlua_model_util_get_id("pink"),    
    ["blue"] = smlua_model_util_get_id("blue"),     
    ["green"] = smlua_model_util_get_id("green"),    
    ["gold"] = smlua_model_util_get_id("gold"),    
    ["black"] = smlua_model_util_get_id("black"),    
    ["red"] = smlua_model_util_get_id("red")    
}    
    
-- Variables del menú    
local FONT_HUD, FONT_NORMAL = 2, 0    
local SOUND_OPEN = 1879113601    
local SOUND_CLOSE = 1881341825    
local SOUND_NAV = 1879113601    
    
-- Variables del mod    
local sparklies_enabled = true    
local sparklie_color = "pink"    
local sparklie_scale = 0.4    
local sparklie_speed = 10    
    
-- Función para obtener el modelo actual    
local function get_current_model()    
    return COLOR_MODELS[sparklie_color] or COLOR_MODELS["pink"]    
end    
    
-- Estructura del menú    
sp_menu = {    
    open = false,    
    selected = 1,    
    colors = { "pink", "blue", "green", "gold", "black", "red" },    
    color_index = 1,    
    move_cooldown = 0,  
    show_credits = false  
}    
    
sp_menu.options = {    
    "Sparklies",    
    "Change Color",       
    "Sparkle Scale",    
    "Sparkle Speed",  
    "Credits"  
}    
    
-- Variables existentes del mod    
local previousPos = {x = 0, y = 0, z = 0}        
local globalTimer = 0        
    
-- Función para dibujar texto con sombra    
local function draw_text_shadow(txt, x, y, scale, r, g, b, a)    
    djui_hud_set_color(0, 0, 0, 180)    
    djui_hud_print_text(txt, x + 3, y + 3, scale)    
    djui_hud_set_color(r, g, b, a)    
    djui_hud_print_text(txt, x, y, scale)    
end    
    
-- Hook para renderizar el menú    
hook_event(HOOK_ON_HUD_RENDER, function()    
    if not sp_menu.open and not sp_menu.show_credits then return end    
    
    local w, h = djui_hud_get_screen_width(), djui_hud_get_screen_height()    
    
    -- Fondo semi-transparente    
    djui_hud_set_color(0, 0, 0, 160)    
    djui_hud_render_rect(0, 0, w, h)    
    
    if sp_menu.show_credits then  
        -- Mostrar pantalla de créditos  
        djui_hud_set_font(FONT_HUD)    
        draw_text_shadow("CREDITS", w * 0.4, 80, 2.5, 255, 255, 255, 255)    
          
        djui_hud_set_font(FONT_NORMAL)    
        draw_text_shadow("Mod creado por:", w * 0.35, 150, 1.5, 255, 255, 255, 255)    
        draw_text_shadow("retired64", w * 0.42, 180, 1.8, 255, 100, 100, 255)    

        draw_text_shadow("¡Gracias por usar el mod!", w * 0.3, 250, 1.5, 255, 255, 100, 255)    
        draw_text_shadow("Presiona B para volver", w * 0.35, h - 100, 1.2, 200, 200, 200, 255)    
    else  
        -- Menú normal  
        -- Título    
        djui_hud_set_font(FONT_HUD)    
        draw_text_shadow("SPARKLIES MENU", w * 0.35, 40, 3, 255, 255, 255, 255)    
    
        djui_hud_set_font(FONT_NORMAL)    
        local baseY = 120    
    
        -- Opciones del menú    
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
            elseif opt == "Sparkle Scale" then    
                value = tostring(sparklie_scale)    
            elseif opt == "Sparkle Speed" then    
                value = tostring(sparklie_speed)    
            elseif opt == "Credits" then    
                value = "Ver créditos"    
            end    
    
            local y = baseY + ((i - 1) * 90)    
            draw_text_shadow(opt, w * 0.25, y, 2, r, g, b, 255)    
            draw_text_shadow(value, w * 0.65, y, 2, r, g, b, 255)    
        end    
    
        -- Instrucciones    
        djui_hud_set_font(FONT_HUD)    
        draw_text_shadow("press B to close", w * 0.25, h - 48, 1.7, 200, 200, 200, 255)    
    end  
end)    
    
-- Hook para manejar input del menú    
hook_event(HOOK_ON_HUD_RENDER, function()    
    if not sp_menu.open and not sp_menu.show_credits then return end    
    
    local m = gMarioStates[0]    
      
    -- Detener movimiento de Mario cuando el menú está abierto    
    m.intendedMag = 0    
    m.input = m.input & ~INPUT_NONZERO_ANALOG    
      
    local pad = m.controller    
    
    sp_menu.move_cooldown = sp_menu.move_cooldown - 1    
    if sp_menu.move_cooldown > 0 then return end    
    
    local moved = false    
    
    -- Cerrar menú o créditos  
    if pad.buttonPressed & B_BUTTON ~= 0 then    
        if sp_menu.show_credits then  
            sp_menu.show_credits = false  
        else  
            sp_menu.open = false    
        end  
        play_sound(SOUND_CLOSE, gGlobalSoundSource)    
        return    
    end    
    
    -- Si estamos en créditos, no procesar navegación del menú  
    if sp_menu.show_credits then return end  
    
    -- Navegación vertical    
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
    
    -- Navegación horizontal para Change Color    
    if sel == "Change Color" then    
        if pad.rawStickX > 60 then    
            sp_menu.color_index = sp_menu.color_index + 1    
            if sp_menu.color_index > #sp_menu.colors then sp_menu.color_index = 1 end    
            sparklie_color = sp_menu.colors[sp_menu.color_index]    
            moved = true    
        elseif pad.rawStickX < -60 then    
            sp_menu.color_index = sp_menu.color_index - 1    
            if sp_menu.color_index < 1 then sp_menu.color_index = #sp_menu.colors end    
            sparklie_color = sp_menu.colors[sp_menu.color_index]    
            moved = true    
        end    
    end    
    
    -- Ajuste de Sparkle Scale    
    if sel == "Sparkle Scale" then    
        if pad.rawStickX > 60 then    
            sparklie_scale = math.min(sparklie_scale + 0.1, 2.0)    
            moved = true    
        elseif pad.rawStickX < -60 then    
            sparklie_scale = math.max(sparklie_scale - 0.1, 0.1)    
            moved = true    
        end    
    end    
    
    -- Ajuste de Sparkle Speed    
    if sel == "Sparkle Speed" then    
        if pad.rawStickX > 60 then    
            sparklie_speed = math.min(sparklie_speed + 1, 50)    
            moved = true    
        elseif pad.rawStickX < -60 then    
            sparklie_speed = math.max(sparklie_speed - 1, 1)    
            moved = true    
        end    
    end    
    
    -- Botón A para toggle o acciones    
    if pad.buttonPressed & A_BUTTON ~= 0 then    
        play_sound(SOUND_NAV, gGlobalSoundSource)    
    
        if sel == "Sparklies" then    
            sparklies_enabled = not sparklies_enabled    
        elseif sel == "Credits" then    
            sp_menu.show_credits = true    
        end    
    end    
    
    if moved then    
        sp_menu.move_cooldown = 8    
    end    
end)    
    
-- Comando para abrir el menú    
hook_chat_command("rd", "- Open sparklies menu", function(msg)    
    sp_menu.open = true    
    sp_menu.show_credits = false  
    play_sound(SOUND_OPEN, gGlobalSoundSource)    
    return true    
end)    
    
-- Tu código original modificado    
hook_event(HOOK_MARIO_UPDATE, function(m)       
    local s = gPlayerSyncTable[m.playerIndex]       
    if m.playerIndex ~= 0 then return end       
    if network_is_server() then s.host = true else s.host = false end       
    
    if not s.host or not sparklies_enabled then return end       
    
    local vel = math.sqrt((m.pos.x - previousPos.x)^2 +        
                         (m.pos.y - previousPos.y)^2 +        
                         (m.pos.z - previousPos.z)^2)       
    
    local interval = 3 - math.min(math.max(vel / 25.0, 0), 2)       
    if globalTimer % math.floor(interval) == 0 then       
        spawn_pink_star_sparkle(m)       
    end       
    
    previousPos = {x = m.pos.x, y = m.pos.y, z = m.pos.z}       
    globalTimer = globalTimer + 1       
end)    
    
hook_event(HOOK_ON_LEVEL_INIT, function()       
    globalTimer = 0       
    previousPos = {x = 0, y = 0, z = 0}       
end)    
    
function spawn_pink_star_sparkle(m)       
    local spawnX = m.pos.x       
    local spawnY = m.pos.y + 50       
    local spawnZ = m.pos.z       
    
    spawn_non_sync_object(       
        id_bhvPinkStarSparkles,       
        get_current_model(),  -- Usa el modelo dinámico       
        spawnX, spawnY, spawnZ,       
        function(o)       
            local sparkleVel = sparklie_speed       
            o.oVelX = sparkleVel * (math.random() - 0.5)       
            o.oVelY = sparkleVel * (math.random() - 0.5)       
            o.oVelZ = sparkleVel * (math.random() - 0.5)       
            o.oScale = sparklie_scale       
            o.oAction = 30       
            o.oAnimState = math.random(0, 1)       
    
            local dv = math.sqrt(o.oVelX^2 + o.oVelY^2 + o.oVelZ^2)       
            local offset = 30       
            if dv ~= 0 then       
                o.oHomeX = offset * (o.oVelX / dv)       
                o.oHomeY = offset * (o.oVelY / dv)       
                o.oHomeZ = offset * (o.oVelZ / dv)       
            else       
                o.oHomeX = 0       
                o.oHomeY = 0       
                o.oHomeZ = 0       
            end       
    
            o.oPosX = m.pos.x + o.oHomeX       
            o.oPosY = m.pos.y + 50 + o.oHomeY       
            o.oPosZ = m.pos.z + o.oHomeZ       
        end       
    )       
end    
    
define_custom_obj_fields({       
    oScale = 'f32',       
})       
    
function pink_star_sparkle_init(o)       
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE       
    o.oAnimState = math.random(0, 1)       
    cur_obj_scale(o.oScale)       
end       
    
function pink_star_sparkle_loop(o, a)       
    obj_set_billboard(o)       
    
    if o.parentObj ~= o then       
        o.oPosX = o.parentObj.oPosX + o.oHomeX + o.oVelX * o.oTimer       
        o.oPosY = o.parentObj.oPosY + o.oHomeY + o.oVelY * o.oTimer       
        o.oPosZ = o.parentObj.oPosZ + o.oHomeZ + o.oVelZ * o.oTimer       
    else       
        o.oPosX = o.oPosX + o.oVelX       
        o.oPosY = o.oPosY + o.oVelY       
        o.oPosZ = o.oPosZ + o.oVelZ       
    end       
    
    o.oAnimState = o.oAnimState + 1       
    
    if o.oTimer > o.oAction then       
        obj_mark_for_deletion(o)       
    end       
end       
    
id_bhvPinkStarSparkles = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, true, pink_star_sparkle_init, pink_star_sparkle_loop)