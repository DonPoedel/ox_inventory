return {
	anim = {
		['eating'] = {
			dict = 'mp_player_inteat@burger',
			clip = 'mp_player_int_eat_burger_fp'
		},
		['use_key'] = {
			dict = 'anim@mp_player_intmenu@key_fob@',
			clip = 'fob_click'
		},
	},
	prop = {
		['burger'] = {
			model = `prop_cs_burger_01`,
			pos = vec3(0.02, 0.02, -0.02),
			rot = vec3(0.0, 0.0, 0.0)
		},
		['key_fob'] = {
			model = `prop_cuff_keys_01`,
			bone = 57005,
			pos = vec3(0.08, 0.02, -0.02),
			rot = vec3(0.0, 0.0, 0.0)
		},
	}
}