local RSGCore = exports['rsg-core']:GetCoreObject()

-----------------------------------------------
-- check player has the craftitems
-----------------------------------------------
RSGCore.Functions.CreateCallback('rsg-camping:server:checkcraftitems', function(source, cb, craftitems, craftamount)
    local src = source
    local hasItems = false
    local icheck = 0
    local Player = RSGCore.Functions.GetPlayer(src)
    for k, v in pairs(craftitems) do
        if Player.Functions.GetItemByName(v.item) and Player.Functions.GetItemByName(v.item).amount >= v.amount * craftamount then
            icheck = icheck + 1
            if icheck == #craftitems then
                cb(true)
            end
        else
            TriggerClientEvent('ox_lib:notify', source, {title = 'Items Needed', description = v.amount..' x '..RSGCore.Shared.Items[v.item].label, type = 'error', duration = 5000 })
            cb(false)
            return
        end
    end
end)

-----------------------------------------------
-- finish crafting
-----------------------------------------------
RegisterServerEvent('rsg-camping:server:finishcrafting')
AddEventHandler('rsg-camping:server:finishcrafting', function(craftitems, receive, giveamount, craftamount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    -- remove craftitems
    for k, v in pairs(craftitems) do
        if Config.Debug == true then
            print(v.item)
            print(v.amount)
        end
        local requiredAmount = v.amount * craftamount
        Player.Functions.RemoveItem(v.item, requiredAmount)    
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[v.item], "remove")
    end
    -- add crafted item
    Player.Functions.AddItem(receive, giveamount * craftamount)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[receive], "add")
    local labelReceive = RSGCore.Shared.Items[receive].label
    TriggerClientEvent('ox_lib:notify', source, {title = 'You Crafted', description = craftamount..' x ' .. labelReceive, type = 'success', duration = 5000 })
end)
