local sfinvpp_path = minetest.get_modpath("sfinvpp")

-- Helper
function mod_loaded(s)
	return minetest.get_modpath(s) ~= nil
end

sfinvpp = {
	mod_3d_armor = mod_loaded("3d_armor")
}

dofile(sfinvpp_path.."/furnace.lua")
dofile(sfinvpp_path.."/chest.lua")
dofile(sfinvpp_path.."/inv.lua")

minetest.register_on_joinplayer(function(player)
	player:get_inventory():set_size("main", (10*6))
	player:hud_set_hotbar_itemcount(10)
	
	player:hud_set_hotbar_image("")
	player:hud_set_hotbar_selected_image("")
end)
