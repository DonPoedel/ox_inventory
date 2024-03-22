local Inventory = require 'modules.inventory.server'
local Items = require 'modules.items.server'

AddEventHandler('zeno:server:player:load', function(source, character)
	-- local inventory = Inventory(source)
	-- if not inventory then return end
	-- inventory.player.groups[inventory.player.gang] = nil
	-- inventory.player.gang = gang.name
	-- inventory.player.groups[gang.name] = gang.grade.level

	local job = nil
	local gang = nil

	if character.job ~= nil then
		job = {}
		job.slug = character.job.slug
		job.role = {}
		job.role.slug = tonumber(character.job.role.slug)
	end
	if character.gang ~= nil then
		gang = {}
		gang.slug = character.gang.name
		gang.role = {}
		gang.slug = tonumber(character.gang.role.slug)
	end

    server.setPlayerInventory(
        {
            source = source,
            name = character.fullname,
			groups = groups,
			dateofbirth = character.date_of_birth,
            identifier = character.id,
			job = job,
			gang = gang,
        }
    )
end)

AddEventHandler('zeno:server:player:unload',
    server.playerDropped
)

---@diagnostic disable-next-line: duplicate-set-field
function server.setPlayerData(player)
	local groups = {}
	local job = nil
	local gang = nil
	if player.job ~= nil then
		job = player.job.slug

		groups[player.job.slug] = tonumber(player.job.role.slug)
	end
	if player.gang ~= nil then
		gang = player.gang.slug
		groups[player.gang.slug] = tonumber(player.gang.role.slug)
	end


	return {
		source = player.source,
		name = player.name,
		groups = groups,
		sex = player.gender,
		dateofbirth = player.date_of_birth,
		job = job,
		gang = gang,
	}
end

---@diagnostic disable-next-line: duplicate-set-field
function server.syncInventory(inv)
	-- local accounts = Inventory.GetAccountItemCounts(inv)

    -- if accounts then
    --     local player = server.GetPlayerFromId(inv.id)
    --     player.Functions.SetPlayerData('items', inv.items)

    --     if accounts.money and accounts.money ~= player.Functions.GetMoney('cash') then
	-- 		player.Functions.SetMoney('cash', accounts.money, "Sync money with inventory")
	-- 	end
	-- end
end

---@diagnostic disable-next-line: duplicate-set-field
function server.hasLicense(inv, license)
	-- local player = server.GetPlayerFromId(inv.id)
	-- return player and player.PlayerData.metadata.licences[license]
end

---@diagnostic disable-next-line: duplicate-set-field
function server.buyLicense(inv, license)
	-- local player = server.GetPlayerFromId(inv.id)
	-- if not player then return end

	-- if player.PlayerData.metadata.licences[license.name] then
	-- 	return false, 'already_have'
	-- elseif Inventory.GetItem(inv, 'money', false, true) < license.price then
	-- 	return false, 'can_not_afford'
	-- end

	-- Inventory.RemoveItem(inv, 'money', license.price)
	-- player.PlayerData.metadata.licences[license.name] = true
	-- player.Functions.SetMetaData('licences', player.PlayerData.metadata.licences)

	-- return true, 'have_purchased'
end

---@diagnostic disable-next-line: duplicate-set-field
function server.isPlayerBoss(playerId)
	-- local Player = QBCore.Functions.GetPlayer(playerId)

	-- return Player.PlayerData.job.isboss or Player.PlayerData.gang.isboss
end