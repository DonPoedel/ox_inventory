if not lib then return end

local Query = {
    SELECT_STASH = 'SELECT data FROM ox_inventory WHERE owner = ? AND name = ?',
    UPDATE_STASH = 'UPDATE ox_inventory SET data = ? WHERE owner = ? AND name = ?',
    UPSERT_STASH =
    'INSERT INTO ox_inventory (data, owner, name) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)',
    INSERT_STASH = 'INSERT INTO ox_inventory (owner, name) VALUES (?, ?)',
    SELECT_GLOVEBOX = 'SELECT plate, glovebox FROM `{vehicle_table}` WHERE `{vehicle_column}` = ?',
    SELECT_TRUNK = 'SELECT plate, trunk FROM `{vehicle_table}` WHERE `{vehicle_column}` = ?',
    SELECT_PLAYER = 'SELECT * FROM `{user_table}` WHERE `{user_column}` = ?',
    UPDATE_TRUNK = 'UPDATE `{vehicle_table}` SET trunk = ? WHERE `{vehicle_column}` = ?',
    UPDATE_GLOVEBOX = 'UPDATE `{vehicle_table}` SET glovebox = ? WHERE `{vehicle_column}` = ?',
    UPDATE_PLAYER = 'UPDATE `{user_table}` SET inventory = ? WHERE `{user_column}` = ?',
}

Citizen.CreateThreadNow(function()
    local playerTable, playerColumn, vehicleTable, vehicleColumn

    if shared.framework == 'ox' then
        playerTable = 'character_inventory'
        playerColumn = 'charid'
        vehicleTable = 'vehicles'
        vehicleColumn = 'id'
    elseif shared.framework == 'esx' then
        playerTable = 'users'
        playerColumn = 'identifier'
        vehicleTable = 'owned_vehicles'
        vehicleColumn = 'plate'
    elseif shared.framework == 'nd' then
		playerTable = 'nd_characters'
		playerColumn = 'charid'
		vehicleTable = 'nd_vehicles'
		vehicleColumn = 'id'
    elseif shared.framework == 'qbx' then
        playerTable = 'players'
        playerColumn = 'citizenid'
        vehicleTable = 'player_vehicles'
        vehicleColumn = 'id'
    elseif shared.framework == 'zeno' then
        playerTable = 'user_character_inventory_items' -- table storing player / character data
        playerColumn = 'character_id'    -- primary key for identifying the character (i.e. identifier, citizenid, id)
        vehicleTable = 'user_character_vehicles'  -- table storing owned vehicle data
        vehicleColumn = 'id'       -- primary key for identifying the vehicle (i.e. plate, vin, id)
    else
        return
    end

    for k, v in pairs(Query) do
        Query[k] = v:gsub('{user_table}', playerTable):gsub('{user_column}', playerColumn):gsub('{vehicle_table}',
            vehicleTable):gsub('{vehicle_column}', vehicleColumn)
    end

    Wait(0)

    local success, result = pcall(MySQL.scalar.await, 'SELECT 1 FROM ox_inventory')

    if not success then
        -- MySQL.query([[CREATE TABLE `ox_inventory` (
		-- 	`owner` varchar(60) DEFAULT NULL,
		-- 	`name` varchar(100) NOT NULL,
		-- 	`data` longtext DEFAULT NULL,
		-- 	`lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
		-- 	UNIQUE KEY `owner` (`owner`,`name`)
		-- )]])
    else
        -- Shouldn't be needed anymore; was used for some data conversion for v2.5.0 (back in March 2022)
        -- result = MySQL.query.await("SELECT owner, name FROM ox_inventory WHERE NOT owner = ''")

        -- if result and next(result) then
        -- 	local parameters = {}
        -- 	local count = 0

        -- 	for i = 1, #result do
        -- 		local data = result[i]
        -- 		local snip = data.name:sub(-#data.owner, #data.name)

        -- 		if data.owner == snip then
        -- 			local name = data.name:sub(0, #data.name - #snip)

        -- 			count += 1
        -- 			parameters[count] = { query = 'UPDATE ox_inventory SET `name` = ? WHERE `owner` = ? AND `name` = ?', values = { name, data.owner, data.name } }
        -- 		end
        -- 	end

        -- 	if #parameters > 0 then
        -- 		MySQL.transaction(parameters)
        -- 	end
        -- end
    end

    result = MySQL.query.await(('SHOW COLUMNS FROM `%s`'):format(vehicleTable))

    if result then
        local glovebox, trunk

        for i = 1, #result do
            local column = result[i]
            if column.Field == 'glovebox' then
                glovebox = true
            elseif column.Field == 'trunk' then
                trunk = true
            end
        end

        -- if not glovebox then
        --     MySQL.query(('ALTER TABLE `%s` ADD COLUMN `glovebox` LONGTEXT NULL'):format(vehicleTable))
        -- end

        -- if not trunk then
        --     MySQL.query(('ALTER TABLE `%s` ADD COLUMN `trunk` LONGTEXT NULL'):format(vehicleTable))
        -- end
    end

    -- success, result = pcall(MySQL.scalar.await, ('SELECT inventory FROM `%s`'):format(playerTable))

    -- if not success then
    --     MySQL.query(('ALTER TABLE `%s` ADD COLUMN `inventory` LONGTEXT NULL'):format(playerTable))
    -- end

    -- local clearStashes = GetConvar('inventory:clearstashes', '6 MONTH')

    -- if clearStashes ~= '' then
    --     pcall(MySQL.query.await, ('DELETE FROM ox_inventory WHERE lastupdated < (NOW() - INTERVAL %s)'):format(clearStashes))
    -- end
end)

db = {}

function db.loadPlayer(identifier)
    local inventory = MySQL.query.await(
        'SELECT * FROM user_character_inventory_items WHERE character_id = "' .. identifier .. '"'
    )

    local items = {}
    if inventory ~= nil then
        for _, item in ipairs(inventory) do
            item.metadata = json.decode(item.metadata)
            table.insert(items, item)
        end
    end

    return items
end

function db.savePlayer(owner, inventory)
    local items = json.decode(inventory)
    local queries = {}
    table.insert(
        queries,
        {
            [[
                DELETE FROM `user_character_inventory_items` WHERE `user_character_inventory_items`.`character_id` = ?
            ]],
            {
                owner
            }
        }
    )
    for k, v in pairs(items) do
        table.insert(
            queries,
            {
                [[
                    INSERT INTO `user_character_inventory_items` (
                        `user_character_inventory_items`.`character_id`,
                        `user_character_inventory_items`.`slot`,
                        `user_character_inventory_items`.`count`,
                        `user_character_inventory_items`.`name`,
                        `user_character_inventory_items`.`metadata`,
                        `user_character_inventory_items`.`created_at`,
                        `user_character_inventory_items`.`updated_at`
                    ) VALUES (
                        ?,
                        ?,
                        ?,
                        ?,
                        ?,
                        NOW(),
                        NOW()
                    )
                ]],
                {
                    owner,
                    v.slot,
                    v.count,
                    v.name,
                    json.encode(v.metadata or {}),
                }
            }
        )
    end

    return MySQL.transaction.await(queries)
end

function db.saveStash(owner, dbId, inventory)
    local items = json.decode(inventory)
    local queries = {}
    table.insert(
        queries,
        {
            [[
                DELETE FROM `world_inventory_items` WHERE `world_inventory_items`.`inventory_id` = ?
            ]],
            {
                dbId
            }
        }
    )
    for k, v in pairs(items) do
        table.insert(
            queries,
            {
                [[
                    INSERT INTO `world_inventory_items` (
                        `world_inventory_items`.`inventory_id`,
                        `world_inventory_items`.`slot`,
                        `world_inventory_items`.`count`,
                        `world_inventory_items`.`name`,
                        `world_inventory_items`.`metadata`,
                        `world_inventory_items`.`created_at`,
                        `world_inventory_items`.`updated_at`
                    ) VALUES (
                        ?,
                        ?,
                        ?,
                        ?,
                        ?,
                        NOW(),
                        NOW()
                    )
                ]],
                {
                    dbId,
                    v.slot,
                    v.count,
                    v.name,
                    json.encode(v.metadata or {}),
                }
            }
        )
    end

    return MySQL.transaction.await(queries)
end

function db.loadStash(owner, name)
    return MySQL.prepare.await(Query.SELECT_STASH, { owner and tostring(owner) or '', name })
end

function db.saveGlovebox(id, inventory)
    local items = json.decode(inventory)
    local queries = {}
    table.insert(
        queries,
        {
            [[
                DELETE FROM `world_inventory_items` WHERE `world_inventory_items`.`inventory_id` = ?
            ]],
            {
                id
            }
        }
    )
    for k, v in pairs(items) do
        table.insert(
            queries,
            {
                [[
                    INSERT INTO `world_inventory_items` (
                        `world_inventory_items`.`inventory_id`,
                        `world_inventory_items`.`slot`,
                        `world_inventory_items`.`count`,
                        `world_inventory_items`.`name`,
                        `world_inventory_items`.`metadata`,
                        `world_inventory_items`.`created_at`,
                        `world_inventory_items`.`updated_at`
                    ) VALUES (
                        ?,
                        ?,
                        ?,
                        ?,
                        ?,
                        NOW(),
                        NOW()
                    )
                ]],
                {
                    id,
                    v.slot,
                    v.count,
                    v.name,
                    json.encode(v.metadata or {}),
                }
            }
        )
    end

    return MySQL.transaction.await(queries)
end

function db.loadGlovebox(id)
    return MySQL.prepare.await(Query.SELECT_GLOVEBOX, { id })
end

function db.saveTrunk(id, inventory)
    local items = json.decode(inventory)
    local queries = {}
    table.insert(
        queries,
        {
            [[
                DELETE FROM `world_inventory_items` WHERE `world_inventory_items`.`inventory_id` = ?
            ]],
            {
                id
            }
        }
    )
    for k, v in pairs(items) do
        for k, v in pairs(items) do
            table.insert(
                queries,
                {
                    [[
                        INSERT INTO `world_inventory_items` (
                            `world_inventory_items`.`inventory_id`,
                            `world_inventory_items`.`slot`,
                            `world_inventory_items`.`count`,
                            `world_inventory_items`.`name`,
                            `world_inventory_items`.`metadata`,
                            `world_inventory_items`.`created_at`,
                            `world_inventory_items`.`updated_at`
                        ) VALUES (
                            ?,
                            ?,
                            ?,
                            ?,
                            ?,
                            NOW(),
                            NOW()
                        )
                    ]],
                    {
                        id,
                        v.slot,
                        v.count,
                        v.name,
                        json.encode(v.metadata or {}),
                    }
                }
            )
        end
    end

    return MySQL.transaction.await(queries)
end

function db.loadTrunk(id)
    return MySQL.prepare.await(Query.SELECT_TRUNK, { id })
end

---@param rows number | MySQLQuery | MySQLQuery[]
local function countRows(rows)
    if type(rows) == 'number' then return rows end

    local n = 0

    for i = 1, #rows do
        if rows[i] == 1 then n += 1 end
    end

    return n
end

local function safeQuery(...)
    local ok, resp = pcall(...)

    if not ok then
        return warn(resp)
    end

    return resp
end

---@param players InventorySaveData[]
---@param trunks InventorySaveData[]
---@param gloveboxes InventorySaveData[]
---@param stashes (InventorySaveData | string | number)[]
---@param total number[]
function db.saveInventories(players, trunks, gloveboxes, stashes, total)
    print('3^Warning this function should not be used!')
    local promises = {}
    local start = os.nanotime()
    local saveStr = 'Saved %d/%d %s (%.4f ms)'
    local pending = 0

    shared.info(('Saving %s inventories to the database'):format(total[5]))

    if total[1] > 0 then
        pending += 1

        Citizen.CreateThreadNow(function()
            local resp = safeQuery(MySQL.prepare.await, Query.UPDATE_PLAYER, players)
            pending -= 1

            if resp then
                shared.info(saveStr:format(countRows(resp), total[1], 'players', (os.nanotime() - start) / 1e6))
            end
        end)
    end

    if total[2] > 0 then
        pending += 1

        Citizen.CreateThreadNow(function()
            local resp = safeQuery(MySQL.prepare.await, Query.UPDATE_TRUNK, trunks)
            pending -= 1

            if resp then
                shared.info(saveStr:format(countRows(resp), total[2], 'trunks', (os.nanotime() - start) / 1e6))
            end
        end)
    end

    if total[3] > 0 then
        pending += 1

        Citizen.CreateThreadNow(function()
            local resp = safeQuery(MySQL.prepare.await, Query.UPDATE_GLOVEBOX, gloveboxes)
            pending -= 1

            if resp then
                shared.info(saveStr:format(countRows(resp), total[3], 'gloveboxes', (os.nanotime() - start) / 1e6))
            end
        end)
    end

    if total[4] > 0 then
        pending += 1

        if server.bulkstashsave then
            total[4] /= 3

            Citizen.CreateThreadNow(function()
                local query = Query.UPSERT_STASH:gsub('%(%?, %?, %?%)', string.rep('(?, ?, ?)', total[4], ', '))
                local resp = safeQuery(MySQL.query.await, query, stashes)
                pending -= 1

                if resp then
                    local affectedRows = resp.affectedRows

                    if total[4] == 1 then
                        if affectedRows == 2 then affectedRows = 1 end
                    else
                        affectedRows -= tonumber(resp.info:match('Duplicates: (%d+)'), 10) or 0
                    end

                    shared.info(saveStr:format(affectedRows, total[4], 'stashes', (os.nanotime() - start) / 1e6))
                end
            end)
        else
            Citizen.CreateThreadNow(function()
                local resp = safeQuery(MySQL.rawExecute.await, Query.UPSERT_STASH, stashes)
                pending -= 1

                if resp then
                    local affectedRows = 0

                    if table.type(resp) == 'hash' then
                        if resp.affectedRows > 0 then affectedRows = 1 end
                    else
                        for i = 1, #resp do
                            if resp[i].affectedRows > 0 then affectedRows += 1 end
                        end
                    end

                    shared.info(saveStr:format('stashes', affectedRows, total[4], (os.nanotime() - start) / 1e6))
                end
            end)
        end
    end

    repeat Wait(0) until pending == 0
end

return db
