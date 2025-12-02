-- name: Fix Whomp's Fortress In Non-Stop (OMM)
-- description: Allows the fortress to appear when playing OMM Rebirth in Non-Stop mode.\n\nMod by EmilyEmmi.

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
        if gServerSettings.stayInLevelAfterStar == 2 and np.currLevelNum == LEVEL_WF and (o.oBehParams >> 24) == 0 then
            set_mario_action(m, _G.OmmApi.ACT_OMM_TRANSITION_WF_TOWER, 0)
        end
    end
end
hook_event(HOOK_ON_INTERACT, on_interact)