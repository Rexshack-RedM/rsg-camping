Config = Config or {}
Config.PlayerProps = {}
Config.Debug = false

-- inventory images
Config.img = "rsg-inventory/html/images/"

-- settings
Config.MenuKeybind          = 'J'
Config.MaxPropCount         = 5 -- maximum props
Config.MaintenancePerCycle  = 1 -- $ amount for prop maintenance
Config.PurgeStorage         = true
Config.BillingCycle         = 1 -- will remove credit every x hour/s
Config.ServerNotify         = true
Config.StorageMaxWeight     = 4000000
Config.StorageMaxSlots      = 48

------------------------------------------------------------------------------------------------------
-- camping equipment
------------------------------------------------------------------------------------------------------
Config.CampingEquipment = {
    [1] = { name = "camphitchpost",   price = 25, amount = 1, info = {}, type = "item", slot = 1, },
    [2] = { name = "campcookstation", price = 30, amount = 1, info = {}, type = "item", slot = 2, },
    [3] = { name = "camptorch",       price = 10, amount = 1, info = {}, type = "item", slot = 3, },
    [4] = { name = "campcrafting",    price = 10, amount = 1, info = {}, type = "item", slot = 4, },
}

Config.CraftingItems = {

    {
        category = "Camping Equipment",
        crafttime = 5000,
        craftitems = { 
            [1] = { item = 'wood',  amount = 3 },
            [2] = { item = 'nails', amount = 1 },
        },
        receive = "camphitchpost",
        giveamount = 1
    },

}
