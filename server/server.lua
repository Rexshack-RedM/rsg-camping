local RSGCore = exports['rsg-core']:GetCoreObject()
local PropsLoaded = false
local CollectedPoop = {}

-----------------------------------------------------------------------

local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'

    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/Rexshack-RedM/rsg-camping/main/version.txt', function(err, text, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')

        if not text then 
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return 
        end

        --versionCheckPrint('success', ('Current Version: %s'):format(currentVersion))
        --versionCheckPrint('success', ('Latest Version: %s'):format(text))
        
        if text == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(text))
        end
    end)
end

-----------------------------------------------------------------------

-- use tent
RSGCore.Functions.CreateUseableItem("camptent", function(source)
    local src = source
    TriggerClientEvent('rsg-camping:client:placeNewProp', src, 'camptent', `mp005_s_posse_tent_bountyhunter07x`, 'camptent')
end)

-- use hitch post
RSGCore.Functions.CreateUseableItem("camphitchpost", function(source)
    local src = source
    TriggerClientEvent('rsg-camping:client:placeNewProp', src, 'camphitchpost', `p_hitchingpost01x`, 'camphitchpost')
end)

-- use cooking station
RSGCore.Functions.CreateUseableItem("campcookstation", function(source)
    local src = source
    TriggerClientEvent('rsg-camping:client:placeNewProp', src, 'campcookstation', `p_campfirecombined03x`, 'campcookstation')
end)

-- use camptorch station
RSGCore.Functions.CreateUseableItem("camptorch", function(source)
    local src = source
    TriggerClientEvent('rsg-camping:client:placeNewProp', src, 'camptorch', `p_torchpost01x`, 'camptorch')
end)

---------------------------------------------
-- get all prop data
---------------------------------------------
RSGCore.Functions.CreateCallback('rsg-camping:server:getallpropdata', function(source, cb, propid)
    MySQL.query('SELECT * FROM player_campsite WHERE propid = ?', {propid}, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

---------------------------------------------
-- update prop data
---------------------------------------------
CreateThread(function()
    while true do
        Wait(5000)

        if PropsLoaded then
            TriggerClientEvent('rsg-camping:client:updatePropData', -1, Config.PlayerProps)
        end
    end
end)

---------------------------------------------
-- get props
---------------------------------------------
CreateThread(function()
    TriggerEvent('rsg-camping:server:getProps')
    PropsLoaded = true
end)

---------------------------------------------
-- save props
---------------------------------------------
RegisterServerEvent('rsg-camping:server:saveProp')
AddEventHandler('rsg-camping:server:saveProp', function(data, propId, citizenid, proptype)
    local datas = json.encode(data)

    MySQL.Async.execute('INSERT INTO player_campsite (properties, propid, citizenid, proptype) VALUES (@properties, @propid, @citizenid, @proptype)',
    {
        ['@properties'] = datas,
        ['@propid'] = propId,
        ['@citizenid'] = citizenid,
        ['@proptype'] = proptype
    })
end)

---------------------------------------------
-- new prop
---------------------------------------------
RegisterServerEvent('rsg-camping:server:newProp')
AddEventHandler('rsg-camping:server:newProp', function(proptype, location, heading, hash)
    local src = source
    local propId = math.random(111111, 999999)
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid

    local PropData =
    {
        id = propId,
        proptype = proptype,
        x = location.x,
        y = location.y,
        z = location.z,
        h = heading,
        hash = hash,
        builder = Player.PlayerData.citizenid,
        buildttime = os.time()
    }

    local PropCount = 0

    for _, v in pairs(Config.PlayerProps) do
        if v.builder == Player.PlayerData.citizenid then
            PropCount = PropCount + 1
        end
    end

    if PropCount >= Config.MaxPropCount then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Max Reached', description = 'you have deployed the max amount!', type = 'inform', duration = 5000 })
    else
        table.insert(Config.PlayerProps, PropData)
        Player.Functions.RemoveItem(proptype, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[proptype], "remove")
        TriggerEvent('rsg-camping:server:saveProp', PropData, propId, citizenid, proptype)
        TriggerEvent('rsg-camping:server:updateProps')
    end
end)

---------------------------------------------
-- distory prop
---------------------------------------------
RegisterServerEvent('rsg-camping:server:destroyProp')
AddEventHandler('rsg-camping:server:destroyProp', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    for k, v in pairs(Config.PlayerProps) do
        if v.id == data.propid then
            table.remove(Config.PlayerProps, k)
        end
    end

    TriggerClientEvent('rsg-camping:client:removePropObject', src, data.propid)
    TriggerEvent('rsg-camping:server:PropRemoved', data.propid)
    TriggerEvent('rsg-camping:server:updateProps')
    Player.Functions.AddItem(data.item, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[data.item], "add")
end)

---------------------------------------------
-- update props
---------------------------------------------
RegisterServerEvent('rsg-camping:server:updateProps')
AddEventHandler('rsg-camping:server:updateProps', function()
    local src = source
    TriggerClientEvent('rsg-camping:client:updatePropData', src, Config.PlayerProps)
end)

RegisterServerEvent('rsg-camping:server:updateCampProps')
AddEventHandler('rsg-camping:server:updateCampProps', function(id, data)
    local result = MySQL.query.await('SELECT * FROM player_campsite WHERE propid = @propid',
    {
        ['@propid'] = id
    })

    if not result[1] then return end

    local newData = json.encode(data)

    MySQL.Async.execute('UPDATE player_campsite SET properties = @properties WHERE propid = @id',
    {
        ['@properties'] = newData,
        ['@id'] = id
    })
end)

---------------------------------------------
-- remove props
---------------------------------------------
RegisterServerEvent('rsg-camping:server:PropRemoved')
AddEventHandler('rsg-camping:server:PropRemoved', function(propId)
    local result = MySQL.query.await('SELECT * FROM player_campsite')

    if not result then return end

    for i = 1, #result do
        local propData = json.decode(result[i].properties)

        if propData.id == propId then
            MySQL.Async.execute('DELETE FROM player_campsite WHERE id = @id',
            {
                ['@id'] = result[i].id
            })

            for k, v in pairs(Config.PlayerProps) do
                if v.id == propId then
                    table.remove(Config.PlayerProps, k)
                end
            end
        end
    end
end)

---------------------------------------------
-- get props
---------------------------------------------
RegisterServerEvent('rsg-camping:server:getProps')
AddEventHandler('rsg-camping:server:getProps', function()
    local result = MySQL.query.await('SELECT * FROM player_campsite')

    if not result[1] then return end

    for i = 1, #result do
        local propData = json.decode(result[i].properties)
        print('loading '..propData.proptype..' prop with ID: '..propData.id)
        table.insert(Config.PlayerProps, propData)
    end
end)

---------------------------------------------
-- add credit
---------------------------------------------
RegisterNetEvent('rsg-camping:server:addcredit', function(newcredit, removemoney, propid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    -- remove money
    Player.Functions.RemoveMoney("cash", removemoney, "camp-credit")
    -- sql update
    MySQL.update('UPDATE player_campsite SET credit = ? WHERE propid = ?', {newcredit, propid})
    -- notify
    TriggerClientEvent('ox_lib:notify', src, {title = 'Credit Added', description = 'credit is now $'..newcredit, type = 'inform', duration = 5000 })
end)

---------------------------------------------
-- remove credit
---------------------------------------------
RegisterNetEvent('rsg-camping:server:removecredit', function(newcredit, addmoney, propid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    -- remove money
    Player.Functions.AddMoney("cash", addmoney, "camp-credit")
    -- sql update
    MySQL.update('UPDATE player_campsite SET credit = ? WHERE propid = ?', {newcredit, propid})
    -- notify
    TriggerClientEvent('ox_lib:notify', src, {title = 'Credit Removed', description = 'credit is now $'..newcredit, type = 'inform', duration = 5000 })
end)

---------------------------------------------
-- remove item
---------------------------------------------
RegisterServerEvent('rsg-camping:server:removeitem')
AddEventHandler('rsg-camping:server:removeitem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    Player.Functions.RemoveItem(item, amount)

    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], "remove")
end)

---------------------------------------------
-- camp upkeep system
---------------------------------------------
UpkeepInterval = function()
    local result = MySQL.query.await('SELECT * FROM player_campsite')

    if not result then goto continue end

    for i = 1, #result do
        local row = result[i]

        if row.credit >= Config.MaintenancePerCycle then
            local creditadjust = (row.credit - Config.MaintenancePerCycle)

            MySQL.update('UPDATE player_campsite SET credit = ? WHERE propid = ?',
            {
                creditadjust,
                row.propid
            })
        else
            MySQL.update('DELETE FROM player_campsite WHERE propid = ?', {row.propid})

            if Config.PurgeStorage then
                MySQL.update('DELETE FROM stashitems WHERE stash = ?', { 'campsite_'..row.citizenid })
            end
            
            if Config.ServerNotify == true then
                print('object with the id of '..row.propid..' owned by the player '..row.citizenid.. ' was deleted')
            end

            TriggerEvent('rsg-log:server:CreateLog', 'camping', 'Camping Object Lost', 'red', row.citizenid..' prop with ID: '..row.propid..' has been lost due to non maintenance!')
        end
    end

    ::continue::

    print('campsite upkeep cycle complete')

    SetTimeout(Config.BillingCycle * (60 * 60 * 1000), UpkeepInterval) -- hours
    --SetTimeout(Config.BillingCycle * (60 * 1000), UpkeepInterval) -- mins (for testing)
end

SetTimeout(Config.BillingCycle * (60 * 60 * 1000), UpkeepInterval) -- hours
--SetTimeout(Config.BillingCycle * (60 * 1000), UpkeepInterval) -- mins (for testing)

--------------------------------------------------------------------------------------------------
-- version check
--------------------------------------------------------------------------------------------------
CheckVersion()
