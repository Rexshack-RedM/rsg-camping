Config = Config or {}
Config.PlayerProps = {}

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
}
