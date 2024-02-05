local Inventory = require 'modules.inventory.server'

AddEventHandler('zeno:server:player:load', function(source, characterId)
	-- local inventory = Inventory(source)
	-- if not inventory then return end
	-- inventory.player.groups[inventory.player.gang] = nil
	-- inventory.player.gang = gang.name
	-- inventory.player.groups[gang.name] = gang.grade.level
    MySQL.query('SELECT * FROM user_character_inventory_items WHERE character_id = ?', {characterId}, function(result)
        local items = {}
        for _, item in ipairs(result) do
            table.insert(items, item)
        end

        server.setPlayerInventory(
            {
                source = source,
                identifier = characterId,
            },
            items
        )
    end)
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