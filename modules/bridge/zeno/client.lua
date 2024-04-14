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

		local groups = PlayerData.groups or {}

		local hasChanges = true
		local jobName = nil
		local gangName = nil

		if state.job ~= nil then
			jobName = state.job.slug
			local level = tonumber(state.job.role.slug)
			if not groups[jobName] or groups[jobName] ~= level then
				hasChanges = true
				groups[jobName] = level
			end
		end

		if state.gang ~= nil then
			gangName = state.gang.name
			local level = tonumber(state.gang.role.slug)
			if not groups[gangName] or groups[gangName] ~= level then
				hasChanges = true
				groups[gangName] = level
			end
		end

		if hasChanges then
			local newGroups = {}
			if jobName ~= nil then
				newGroups[jobName] = groups[jobName]
			end
			if gangName ~= nil then
				newGroups[gangName] = groups[gangName]
			end

			PlayerData.groups = newGroups
			OnPlayerData('groups', PlayerData.groups)
		end
    end
end)