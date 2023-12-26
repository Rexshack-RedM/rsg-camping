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
    local query = 'SELECT * FROM player_campsite WHERE propid = @propid'
    local parameters = {['@propid'] = propid}

    MySQL.query(query, parameters, function(result)
        if result then
            cb(result[1])  
        else
            cb(nil)
        end
    end)
end)


---------------------------------------------
-- count props
---------------------------------------------
RSGCore.Functions.CreateCallback('rsg-camping:server:countprop', function(source, cb, proptype)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid

    local query = 'SELECT COUNT(*) as count FROM player_campsite WHERE citizenid = ? AND proptype = ?'
    local values = {citizenid, proptype}

    local success, count = pcall(function()
        return MySQL.Sync.fetchScalar(query, values)
    end)

    if success then
        cb(count)
    else
        print("Error in database query:", count)
        cb(nil)        
    end
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

    local query = 'INSERT INTO player_campsite (properties, propid, citizenid, proptype) VALUES (@properties, @propid, @citizenid, @proptype)'
    local values = {
        ['@properties'] = datas,
        ['@propid'] = propId,
        ['@citizenid'] = citizenid,
        ['@proptype'] = proptype
    }

    local success, _ = pcall(function()
        MySQL.Async.execute(query, values)
    end)

    if not success then
        print("Error saving prop to the database")        
    end
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

    if not result[1] then
        return
    end

    local newData = json.encode(data)

    local updateQuery = 'UPDATE player_campsite SET properties = @properties WHERE propid = @id'
    local updateValues = {
        ['@properties'] = newData,
        ['@id'] = id
    }

    local success, _ = pcall(function()
        MySQL.Async.execute(updateQuery, updateValues)
    end)

    if not success then
        print("Error updating campsite properties")        
    end
end)


---------------------------------------------
-- remove props
---------------------------------------------
RegisterServerEvent('rsg-camping:server:PropRemoved')
AddEventHandler('rsg-camping:server:PropRemoved', function(propId)
    local result = MySQL.query.await('SELECT * FROM player_campsite WHERE propid = @propid',
    {
        ['@propid'] = propId
    })

    if not result or not result[1] then
        return
    end

    local propData = json.decode(result[1].properties)

    local success, _ = pcall(function()
        MySQL.Async.execute('DELETE FROM player_campsite WHERE propid = @propid',
        {
            ['@propid'] = propId
        })
    end)

    if not success then
        print("Error removing campsite property from the database")        
        return
    end

    for k, v in pairs(Config.PlayerProps) do
        if v.id == propId then
            table.remove(Config.PlayerProps, k)
        end
    end
end)


---------------------------------------------
-- get props
---------------------------------------------
RegisterServerEvent('rsg-camping:server:getProps')
AddEventHandler('rsg-camping:server:getProps', function()
    local result = MySQL.query.await('SELECT * FROM player_campsite')

    if not result or not result[1] then
        print("Error fetching campsite properties from the database")        
        return
    end

    for i = 1, #result do
        local propData = json.decode(result[i].properties)
        print(('Loading %s prop with ID: %s'):format(propData.proptype, propData.id))
        table.insert(Config.PlayerProps, propData)
    end
end)


---------------------------------------------
-- add credit
---------------------------------------------
RegisterNetEvent('rsg-camping:server:addcredit')
AddEventHandler('rsg-camping:server:addcredit', function(newcredit, removemoney, propid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    -- Retirar dinero
    Player.Functions.RemoveMoney("cash", removemoney, "camp-credit")

    -- Actualizar crédito en la base de datos
    local updateQuery = 'UPDATE player_campsite SET credit = ? WHERE propid = ?'
    local updateValues = {newcredit, propid}

    local success, _ = pcall(function()
        MySQL.Async.execute(updateQuery, updateValues)
    end)

    if not success then
        print("Error updating campsite credit in the database")
        -- Trata el error de alguna manera
        return
    end

    -- Notificar al cliente
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Credit Added',
        description = ('Credit is now $%s'):format(newcredit),
        type = 'inform',
        duration = 5000
    })
end)


---------------------------------------------
-- remove credit
---------------------------------------------
RegisterNetEvent('rsg-camping:server:removecredit')
AddEventHandler('rsg-camping:server:removecredit', function(newcredit, addmoney, propid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    Player.Functions.AddMoney("cash", addmoney, "camp-credit")

    local updateQuery = 'UPDATE player_campsite SET credit = ? WHERE propid = ?'
    local updateValues = {newcredit, propid}

    local success, _ = pcall(function()
        MySQL.Async.execute(updateQuery, updateValues)
    end)

    if not success then
        print("Error updating campsite credit in the database")        
        return
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Credit Removed',
        description = ('Credit is now $%s'):format(newcredit),
        type = 'inform',
        duration = 5000
    })
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
                MySQL.update('DELETE FROM stashitems WHERE stash = ?', { 'camp_'..row.citizenid })
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
