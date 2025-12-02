local ipairs, obj_field, chat_cmd, chat_msg, get_model_id, storage_exists, storage_save, storage_load, scale_obj, set_billboard, mark_delete, vec_len, hook_bhv, hook_ev, discord_id, spwn_sobj, clamp, OBJ_FLAG_SET_FACE_ANGLE_TO_MOVE_ANGLE, OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE, coop_id, global_from_local = ipairs, define_custom_obj_fields, hook_chat_command, djui_chat_message_create, smlua_model_util_get_id, mod_storage_exists, mod_storage_save, mod_storage_load, cur_obj_scale, obj_set_billboard, obj_mark_for_deletion, vec3f_length, hook_behavior, hook_event, network_discord_id_from_local_index, spawn_sync_object, clamp, OBJ_FLAG_SET_FACE_ANGLE_TO_MOVE_ANGLE, OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE, get_coopnet_id, network_global_index_from_local


local function is_dev(m)  
    return true 
end

define_custom_obj_fields({
    oHatOwner = 'u32',
})

local HAT_NONE = 0
local HAT_DEVHALO = 1
local HAT_CODEVHALO = 2

local gHatList = {
    [HAT_DEVHALO] = { model = smlua_model_util_get_id("devhalo"), cap = true },
    [HAT_CODEVHALO] = { model = smlua_model_util_get_id("codevhalo"), cap = true }
}

local function active_player(m)
    local np = gNetworkPlayers[m.playerIndex]
    if m.playerIndex == 0 then return 1 end
    if not np.connected then return 0 end
    if np.currCourseNum ~= gNetworkPlayers[0].currCourseNum then return 0 end
    if np.currActNum ~= gNetworkPlayers[0].currActNum then return 0 end
    if np.currLevelNum ~= gNetworkPlayers[0].currLevelNum then return 0 end
    if np.currAreaIndex ~= gNetworkPlayers[0].currAreaIndex then return 0 end
    return is_player_active(m)
end

local function bhv_hat_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    cur_obj_scale(1.3)
    o.hitboxRadius = 0
    o.hitboxHeight = 0
    cur_obj_hide()
end

local function bhv_hat_loop(o)  
    local np = network_player_from_global_index(o.oHatOwner)  
    if np == nil or not gPlayerSyncTable[np.localIndex] or gPlayerSyncTable[np.localIndex].hat == HAT_NONE then  
        obj_mark_for_deletion(o)  
        return  
    end 

    local m = gMarioStates[np.localIndex]
    if active_player(m) == 0 then
        obj_mark_for_deletion(o)
        return
    end

    if m.marioBodyState.updateTorsoTime == gMarioStates[0].marioBodyState.updateTorsoTime
        and m.action ~= ACT_DISAPPEARED and m.action ~= ACT_IN_CANNON then
       
        local DEVHALO_OFFSET_Y = -13
        local CODEVHALO_OFFSET_Y = -13

        o.oPosY = m.marioBodyState.headPos.y + m.vel.y + DEVHALO_OFFSET_Y + CODEVHALO_OFFSET_Y
        o.oPosX = m.marioBodyState.headPos.x + m.vel.x
        o.oPosZ = m.marioBodyState.headPos.z + m.vel.z
        cur_obj_unhide()
    else
        vec3f_to_object_pos(o, m.pos)
        cur_obj_hide()
    end

    if gPlayerSyncTable[m.playerIndex] and gHatList[gPlayerSyncTable[m.playerIndex].hat] then  
        obj_set_model_extended(o, gHatList[gPlayerSyncTable[m.playerIndex].hat].model)  
    end
end

local id_bhvHat = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_hat_init, bhv_hat_loop)

local function mario_update_hat(m)
    local spawned = false
    local hat = obj_get_first_with_behavior_id(id_bhvHat)

    while hat ~= nil do
        if hat.oHatOwner == gNetworkPlayers[m.playerIndex].globalIndex then
            spawned = true
            break
        end
        hat = obj_get_next_with_same_behavior_id(hat)
    end

    if not spawned then
        spawn_non_sync_object(id_bhvHat, E_MODEL_NONE, m.pos.x, m.pos.y, m.pos.z, function(o)
            o.oHatOwner = gNetworkPlayers[m.playerIndex].globalIndex
        end)
    end
end

hook_event(HOOK_MARIO_UPDATE, mario_update_hat)

local E_MODEL_CROWN   = get_model_id("crown")
local E_MODEL_GLASSES = get_model_id("glasses")

local function mario_update_models(m)
    local sync = gPlayerSyncTable[m.playerIndex]

    if sync.devModel == "crown" then
        obj_set_model_extended(m.marioObj, E_MODEL_CROWN)
    elseif sync.devModel == "glasses" then
        obj_set_model_extended(m.marioObj, E_MODEL_GLASSES)
    else
        obj_set_model_extended(m.marioObj, E_MODEL_MARIO)
    end
end

hook_event(HOOK_MARIO_UPDATE, mario_update_models)

chat_cmd("dev", "- Developer features", function(msg)  
    local m = gMarioStates[0]  
    msg = string.lower(msg or "")  
    local sync = gPlayerSyncTable[m.playerIndex]  
  
    if msg == "yusuke" then  
        sync.devModel = "none"  
        sync.hat = HAT_DEVHALO  
        djui_chat_message_create("\\#ffff00\\Owner Feature: \\#00ff00\\Enabled")  
        return true  
    end  
  
    if msg == "tilin" then  
        sync.devModel = "none"  
        sync.hat = HAT_CODEVHALO  
        djui_chat_message_create("\\#ffff00\\Owner Feature: \\#00ff00\\Enabled")  
        return true  
    end  
  
    if msg == "crown" then  
        sync.hat = HAT_NONE  
        sync.devModel = "crown"  
        djui_chat_message_create("\\#ffff00\\Developer Feature: \\#00ff00\\Enabled")  
        return true  
    end  
  
    if msg == "glasses" then  
        sync.hat = HAT_NONE  
        sync.devModel = "glasses"  
        djui_chat_message_create("\\#ffff00\\Developer Feature: \\#00ff00\\Enabled")  
        return true  
    end  
  
    if msg == "off" then  
        local was_owner = (sync.hat == HAT_DEVHALO or sync.hat == HAT_CODEVHALO)  
        sync.hat = HAT_NONE  
        sync.devModel = "none"  
  
        if was_owner then  
            djui_chat_message_create("\\#ffff00\\Owner Feature: \\#F80000\\Disabled")  
        else  
            djui_chat_message_create("\\#ffff00\\Developer Feature: \\#F80000\\Disabled")  
        end  
  
        return true  
    end  
  
    djui_chat_message_create("\\#ffff00\\Usage: \\#ffffff\\/dev [yusuke|tilin|crown|glasses|off]")  
    return true  
end)