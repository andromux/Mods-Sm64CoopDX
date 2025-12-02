-- name: Teleport to Cappy

local m0 = gMarioStates[0]

hook_event(HOOK_UPDATE, function ()
    if bhvOmmCappy then
        if m0.controller and m0.controller.buttonPressed & L_TRIG ~= 0 then
            local cappy = obj_get_first_with_behavior_id_and_field_s32(bhvOmmCappy, 0x31, network_global_index_from_local(0) + 1)
            if cappy and cappy.oSubAction ~= 0 then
                cappy.oSubAction = 0
                m0.pos.x = cappy.oPosX
                m0.pos.y = cappy.oPosY
                m0.pos.z = cappy.oPosZ
            end
        end
    end
end)
