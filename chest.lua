local S = default.get_translator

-- Most code here is from the default chests
function default.chest.get_chest_formspec(pos)
	local spos = pos.x .. "," .. pos.y .. "," .. pos.z
	local meta = minetest.get_meta(pos)
	local is_big = meta:get_inventory():get_size("main") == 10*5
	local formspec =
		"size[8,10.2]" ..
		(is_big and "style_type[list;size=.89;spacing=.1]" or "") ..
		"list[nodemeta:" .. spos .. ";main;0,0.3;".. (is_big and "10,5" or "8,4") ..";]" ..
		"style_type[list;size=.89;spacing=.1]" ..
		"list[current_player;main;0,4.85;10,1;]" ..
		"list[current_player;main;0,6.08;10,6;10]" ..
		"listring[nodemeta:" .. spos .. ";main]" ..
		"listring[current_player;main]"
	return formspec
end


function default.chest.register_chest(prefixed_name, d)
	local name = prefixed_name:sub(1,1) == ':' and prefixed_name:sub(2,-1) or prefixed_name
	local def = table.copy(d)
	def.drawtype = "mesh"
	def.visual = "mesh"
	def.paramtype = "light"
	def.paramtype2 = "facedir"
	def.legacy_facedir_simple = true
	def.is_ground_content = false

	if def.protected then
		def.on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", S("Locked Big Chest"))
			meta:set_string("owner", "")
			local inv = meta:get_inventory()
			inv:set_size("main", 10*5)
		end
		def.after_place_node = function(pos, placer)
			local meta = minetest.get_meta(pos)
			meta:set_string("owner", placer:get_player_name() or "")
			meta:set_string("infotext", S("Locked Big Chest (owned by @1)", meta:get_string("owner")))
		end
		def.can_dig = function(pos,player)
			local meta = minetest.get_meta(pos);
			local inv = meta:get_inventory()
			return inv:is_empty("main") and
					default.can_interact_with_node(player, pos)
		end
		def.allow_metadata_inventory_move = function(pos, from_list, from_index,
				to_list, to_index, count, player)
			if not default.can_interact_with_node(player, pos) then
				return 0
			end
			return count
		end
		def.allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			if not default.can_interact_with_node(player, pos) then
				return 0
			end
			return stack:get_count()
		end
		def.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
			if not default.can_interact_with_node(player, pos) then
				return 0
			end
			return stack:get_count()
		end
		def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if not default.can_interact_with_node(clicker, pos) then
				return itemstack
			end

			local cn = clicker:get_player_name()

			if default.chest.open_chests[cn] then
				default.chest.chest_lid_close(cn)
			end

			minetest.sound_play(def.sound_open, {gain = 0.3,
					pos = pos, max_hear_distance = 10}, true)
			if not default.chest.chest_lid_obstructed(pos) then
				minetest.swap_node(pos,
						{ name = name .. "_open",
						param2 = node.param2 })
			end
			minetest.after(0.2, minetest.show_formspec, cn,
					"default:chest", default.chest.get_chest_formspec(pos))
			default.chest.open_chests[cn] = { pos = pos,
					sound = def.sound_close, swap = name }
		end
		def.on_blast = function() end
		def.on_key_use = function(pos, player)
			local secret = minetest.get_meta(pos):get_string("key_lock_secret")
			local itemstack = player:get_wielded_item()
			local key_meta = itemstack:get_meta()

			if itemstack:get_metadata() == "" then
				return
			end

			if key_meta:get_string("secret") == "" then
				key_meta:set_string("secret", minetest.parse_json(itemstack:get_metadata()).secret)
				itemstack:set_metadata("")
			end

			if secret ~= key_meta:get_string("secret") then
				return
			end

			minetest.show_formspec(
				player:get_player_name(),
				"default:chest_locked",
				default.chest.get_chest_formspec(pos)
			)
		end
		def.on_skeleton_key_use = function(pos, player, newsecret)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("owner")
			local pn = player:get_player_name()

			-- verify placer is owner of lockable chest
			if owner ~= pn then
				minetest.record_protection_violation(pos, pn)
				minetest.chat_send_player(pn, S("You do not own this chest."))
				return nil
			end

			local secret = meta:get_string("key_lock_secret")
			if secret == "" then
				secret = newsecret
				meta:set_string("key_lock_secret", secret)
			end

			return secret, S("a locked chest"), owner
		end
	else
		def.on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", S("Big Chest"))
			local inv = meta:get_inventory()
			inv:set_size("main", 10*5)
		end
		def.can_dig = function(pos,player)
			local meta = minetest.get_meta(pos);
			local inv = meta:get_inventory()
			return inv:is_empty("main")
		end
		def.on_rightclick = function(pos, node, clicker)
			local cn = clicker:get_player_name()

			if default.chest.open_chests[cn] then
				default.chest.chest_lid_close(cn)
			end

			minetest.sound_play(def.sound_open, {gain = 0.3, pos = pos,
					max_hear_distance = 10}, true)
			if not default.chest.chest_lid_obstructed(pos) then
				minetest.swap_node(pos, {
						name = name .. "_open",
						param2 = node.param2 })
			end
			minetest.after(0.2, minetest.show_formspec,
					cn,
					"default:chest", default.chest.get_chest_formspec(pos))
			default.chest.open_chests[cn] = { pos = pos,
					sound = def.sound_close, swap = name }
		end
		def.on_blast = function(pos)
			local drops = {}
			default.get_inventory_drops(pos, "main", drops)
			drops[#drops+1] = name
			minetest.remove_node(pos)
			return drops
		end
	end

	default.set_inventory_action_loggers(def, "chest")

	local def_opened = table.copy(def)
	local def_closed = table.copy(def)

	def_opened.mesh = "chest_open.obj"
	for i = 1, #def_opened.tiles do
		if type(def_opened.tiles[i]) == "string" then
			def_opened.tiles[i] = {name = def_opened.tiles[i], backface_culling = true}
		elseif def_opened.tiles[i].backface_culling == nil then
			def_opened.tiles[i].backface_culling = true
		end
	end
	def_opened.drop = name
	def_opened.groups.not_in_creative_inventory = 1
	def_opened.selection_box = {
		type = "fixed",
		fixed = { -1/2, -1/2, -1/2, 1/2, 3/16, 1/2 },
	}
	def_opened.can_dig = function()
		return false
	end
	def_opened.on_blast = function() end

	def_closed.mesh = nil
	def_closed.drawtype = nil
	def_closed.tiles[6] = def.tiles[5] -- swap textures around for "normal"
	def_closed.tiles[5] = def.tiles[3] -- drawtype to make them match the mesh
	def_closed.tiles[3] = def.tiles[3].."^[transformFX"

	minetest.register_node(prefixed_name, def_closed)
	minetest.register_node(prefixed_name .. "_open", def_opened)

	-- convert old chests to this new variant
	if name == "default:chest" or name == "default:chest_locked" then
		minetest.register_lbm({
			label = "update chests to opening chests",
			name = "default:upgrade_" .. name:sub(9,-1) .. "_v2",
			nodenames = {name},
			action = function(pos, node)
				local meta = minetest.get_meta(pos)
				meta:set_string("formspec", nil)
				local inv = meta:get_inventory()
				local list = inv:get_list("default:chest")
				if list then
					inv:set_size("main", 8*4)
					inv:set_list("main", list)
					inv:set_list("default:chest", nil)
				end
			end
		})
	end

	-- close opened chests on load
	local modname, chestname = prefixed_name:match("^(:?.-):(.*)$")
	minetest.register_lbm({
		label = "close opened chests on load",
		name = modname .. ":close_" .. chestname .. "_open",
		nodenames = {prefixed_name .. "_open"},
		run_at_every_load = true,
		action = function(pos, node)
			node.name = prefixed_name
			minetest.swap_node(pos, node)
		end
	})
end

-- Also add some big ones
default.chest.register_chest("sfinvpp:chest", {
	description = S("Big Chest"),
	tiles = {
		"default_chest_top.png",
		"default_chest_top.png",
		"default_chest_side.png",
		"default_chest_side.png",
		"sfinv_big_chest_front.png",
		"default_chest_inside.png"
	},
	sounds = default.node_sound_wood_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
})

default.chest.register_chest("sfinvpp:chest_locked", {
	description = S("Big Locked Chest"),
	tiles = {
		"default_chest_top.png",
		"default_chest_top.png",
		"default_chest_side.png",
		"default_chest_side.png",
		"sfinv_big_chest_lock.png",
		"default_chest_inside.png"
	},
	sounds = default.node_sound_wood_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	protected = true,
})

-- And the recipes
minetest.register_craft({
	output = "sfinvpp:big_chest",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"default:diamond", "", "default:diamond"},
		{"group:wood", "group:wood", "group:wood"},
	}
})

minetest.register_craft({
	output = "sfinvpp:big_chest_locked",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"default:diamond", "default:steel_ingot", "default:diamond"},
		{"group:wood", "group:wood", "group:wood"},
	}
})

minetest.register_craft( {
	type = "shapeless",
	output = "sfinvpp:big_chest_locked",
	recipe = {"sfinvpp:big_chest", "default:steel_ingot"},
})

minetest.register_craft({
	type = "fuel",
	recipe = "sfinvpp:big_chest",
	burntime = 50,
})

minetest.register_craft({
	type = "fuel",
	recipe = "sfinv:big_chest_locked",
	burntime = 50,
})

