local Inventory = require 'modules.inventory.client'
local Weapon = require 'modules.weapon.client'

RegisterNetEvent('zeno:client:player:load', function(character)
	if character.health == 0 then
		OnPlayerData('dead', 1)
	end

	local groups = PlayerData.groups or {}
	if character.job ~= nil then
		groups[character.job.slug] = tonumber(character.job.role.slug)
	end
	if character.gang ~= nil then
		groups[character.gang.slug] = tonumber(character.gang.role.slug)
	end

	OnPlayerData('groups', groups)
end)

RegisterNetEvent('zeno:client:player:unload',
    client.onLogout
)

AddEventHandler('zeno:client:regionManager:playerUpdate', function(isPlayer, ped, index, state)
	if state ~= nil and isPlayer then
		if state.status.health == 0 then
			OnPlayerData('dead', 1)
		end

		local groups = PlayerData.groups
		local job = {}
		local gang = {}

		if state.job ~= nil then
			job.name = state.job.slug
			job.level = tonumber(state.job.role.slug)
		end
		if state.gang ~= nil then
			gang.name = state.gang.slug
			gang.level = tonumber(state.gang.role.slug)
		end

		if not groups[job.slug]
			or not groups[gang.slug]
			or groups[job.slug] ~= tonumber(job.role.slug)
			or groups[gang.slug] ~= tonumber(role.slug)
		then
			PlayerData.groups = {
				[job.slug] = tonumber(job.role.slug),
				[gang.slug] = tonumber(gang.role.slug),
			}

			OnPlayerData('groups', PlayerData.groups)
		end
    end
end)