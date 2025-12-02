-- name: Disable OMM Moveset
-- description: Forces the OMM Rebirth moveset to be disabled for all players. Useful if you would like to use the other features of the mod.\n\nMod by EmilyEmmi.

local alreadyChecked = false
local OMMExists = false
function update()
    if not alreadyChecked then
        if _G.OmmApi then
            local verstring = (_G.OmmVersion and _G.OmmVersion:sub(9)) or "Unknown"
            if tonumber(verstring) and tonumber(verstring) < 1.2 then
                djui_popup_create(
                    string.format("Bad OMM Version!\nMinimum version: %s\nYour version: %s", "1.2", verstring),
                    3)
            end
            _G.OmmApi.omm_force_setting("moveset", 0)
            _G.OmmApi.omm_force_setting("cappy", 0)
            OMMExists = true
        else
            djui_popup_create("You gotta enable OMM Rebirth, silly!", 3)
        end
        alreadyChecked = true
    end
end
hook_event(HOOK_UPDATE, update)

-- fix whomp king
function on_interact(m, o, type, value)
    if OMMExists and _G.OmmGame == "Super Mario 64" and type == INTERACT_STAR_OR_KEY then
        local np = gNetworkPlayers[m.playerIndex]
        if gServerSettings.stayInLevelAfterStar ~= 0 and np.currLevelNum == LEVEL_WF and (o.oBehParams >> 24) == 0 then
            set_mario_action(m, _G.OmmApi.ACT_OMM_TRANSITION_WF_TOWER, 0)
        end
    end
end
hook_event(HOOK_ON_INTERACT, on_interact)