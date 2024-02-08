local Inventory = require 'modules.inventory.server'

AddEventHandler('zeno:server:player:load', function(source, character)
	-- local inventory = Inventory(source)
	-- if not inventory then return end
	-- inventory.player.groups[inventory.player.gang] = nil
	-- inventory.player.gang = gang.name
	-- inventory.player.groups[gang.name] = gang.grade.level

    server.setPlayerInventory(
        {
            source = source,
            name = character.fullname,
            identifier = character.id,
        }
    )
end)

AddEventHandler('zeno:server:player:unload',
    server.playerDropped
)

-- function server.syncInventory(inv)
-- 	local accounts = Inventory.GetAccountItemCounts(inv)

--     if accounts then
--         local player = server.GetPlayerFromId(inv.id)
--         player.Functions.SetPlayerData('items', inv.items)

--         if accounts.money and accounts.money ~= player.Functions.GetMoney('cash') then
-- 			player.Functions.SetMoney('cash', accounts.money, "Sync money with inventory")
-- 		end
-- 	end
-- end