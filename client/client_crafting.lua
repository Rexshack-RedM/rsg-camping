local RSGCore = exports['rsg-core']:GetCoreObject()

-----------------------------------------------
-- target for camp crafting table
-----------------------------------------------
exports['rsg-target']:AddTargetModel(`mp005_s_posse_ammotable03x`, {
    options = {
        {
            type = "client",
            event = 'rsg-camping:client:craftmenu',
            icon = "far fa-eye",
            label = 'Open Crafting Menu',
            distance = 3.0
        },
    }
})

-----------------------------------------------
-- create a table to store menu options by category
-----------------------------------------------
local categoryMenus = {}

-----------------------------------------------
-- iterate through recipes and organize them by category
-----------------------------------------------
for _, v in ipairs(Config.CraftingItems) do
    local craftitemsMetadata = {}
    local setheader = RSGCore.Shared.Items[tostring(v.receive)].label
    local itemimg = "nui://"..Config.img..RSGCore.Shared.Items[tostring(v.receive)].image
    for i, craftitems in ipairs(v.craftitems) do
        table.insert(craftitemsMetadata, { label = RSGCore.Shared.Items[craftitems.item].label, value = craftitems.amount })
    end
    local option = {
        title = setheader,
        icon = itemimg,
        event = 'rsg-camping:client:checkcraftitems',
        metadata = craftitemsMetadata,
        args = {
            title = setheader,
            craftitems = v.craftitems,
            crafttime = v.crafttime,
            receive = v.receive,
            giveamount = v.giveamount
        }
    }

    if not categoryMenus[v.category] then
        categoryMenus[v.category] = {
            id = 'crafting_menu_' .. v.category,
            title = v.category,
            menu = 'crafting_main_menu',
            onBack = function() end,
            options = { option }
        }
    else
        table.insert(categoryMenus[v.category].options, option)
    end
end

-----------------------------------------------
-- log menu events by category
-----------------------------------------------
for category, menuData in pairs(categoryMenus) do
    RegisterNetEvent('rsg-camping:client:' .. category)
    AddEventHandler('rsg-camping:client:' .. category, function()
        lib.registerContext(menuData)
        lib.showContext(menuData.id)
    end)
end

-----------------------------------------------
-- crafting main menu
-----------------------------------------------
RegisterNetEvent('rsg-camping:client:craftmenu')
AddEventHandler('rsg-camping:client:craftmenu', function()
    local mainMenu = {
        id = 'crafting_main_menu',
        title = 'Crafting Main Menu',
        options = {}
    }

    for category, menuData in pairs(categoryMenus) do
        table.insert(mainMenu.options, {
            title = category,
            --description = 'Explore the recipes for ' .. category,
            icon = 'fa-solid fa-pen-ruler',
            event = 'rsg-camping:client:' .. category,
            arrow = true
        })
    end

    lib.registerContext(mainMenu)
    lib.showContext(mainMenu.id)
end)

-----------------------------------------------
-- check player has the crafting items to craft the item
-----------------------------------------------
RegisterNetEvent('rsg-camping:client:checkcraftitems', function(data)
    local input = lib.inputDialog('Craft Amount', {
        { 
            type = 'input',
            label = 'Amount',
            required = true,
            min = 1, max = 10 
        },
    })

    if not input then return end

    local craftamount = tonumber(input[1])
    if craftamount then
        RSGCore.Functions.TriggerCallback('rsg-camping:server:checkcraftitems', function(hasRequired)
            if (hasRequired) then
                if Config.Debug == true then
                    print("passed")
                end
                TriggerEvent('rsg-camping:client:craftitems', data.title, data.craftitems, tonumber(data.crafttime * craftamount), data.receive, data.giveamount, craftamount)
            else
                if Config.Debug == true then
                    print("failed")
                end
                return
            end
        end, data.craftitems,  craftamount)
    end
end)

-----------------------------------------------
-- do crafting
-----------------------------------------------
RegisterNetEvent('rsg-camping:client:craftitems', function(title, craftitems, crafttime, receive, giveamount, craftamount)

    if lib.progressBar({
        duration = crafttime,
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disableControl = true,
        label = 'Crafting ' .. title,
        anim = {
            dict = 'mech_inventory@crafting@fallbacks',
            clip = 'full_craft_and_stow',
            flag = 27,
        },
    }) then
        -- crafting was successful
        TriggerServerEvent('rsg-camping:server:finishcrafting', craftitems, receive, giveamount, craftamount)
    else
        lib.notify({ title = 'Crafting Failed!', type = 'error', duration = 5000 })
    end

end)
