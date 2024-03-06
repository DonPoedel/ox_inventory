return {
	['money'] = {
		label = 'Money',
	},

	['vehicle_key'] = {
		label = 'Vehicle Key',
		stack = false,
		allowedArmed = true,
		consume = 0,
		weight = 1,
		client = {
			usetime = 500,
			anim = 'use_key',
			prop = 'key_fob'
		},
		server = {
			export = 'core.inventoryItemEvent',
		},
	},

	['burger'] = {
		label = 'Burger',
		weight = 220,
		stack = true,
		close = true,
		client = {
			usetime = 2500,
			anim = 'eating',
			prop = 'burger'
		},
		server = {
			export = 'core.inventoryItemEvent',
		},
	},
}
