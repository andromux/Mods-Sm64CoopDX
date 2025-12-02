-- name: Infinite Cappy bounces

hook_event(HOOK_UPDATE, function ()
    if _G.OmmEnabled then
        local obj = obj_get_first_with_behavior_id(bhvOmmCappy)
        while obj ~= nil do
            obj.oCapUnkF4 = 0
            obj = obj_get_next_with_same_behavior_id(obj)
        end
    end
end)
