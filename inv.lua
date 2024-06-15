sfinv.theme_inv = [[
		style_type[list;size=.89;spacing=.1]
		list[current_player;main;0,5.2;10,1;]
		list[current_player;main;0,6.35;10,6;10]
		style_type[list;size=1;spacing=.25,.17]
	]]

		
function sfinv.make_formspec(player, context, content, show_inv, size)
	local tmp = {
		size or "size[8,10.43]",
		sfinv.get_nav_fs(player, context, context.nav_titles, context.nav_idx),
		show_inv and sfinv.theme_inv or "",
		content
	}
	return table.concat(tmp, "")
end

local trash = minetest.create_detached_inventory("sfinvpptrash", {
	allow_put = function(_,_,_,stack)
		return stack:get_count()
	end,
	on_put = function(inv, listname, _, _, player)
		inv:set_list(listname, {})
	end
})
trash:set_size("main", 1)

-- default
default.gui_survival_form = "size[8,10.43]"..
			"list[current_player;main;0,4.25;10,1;]"..
			"list[current_player;main;0,5.5;10,6;10]"..
			"list[current_player;craft;1.75,0.5;5,3;]"..
			"list[current_player;craftpreview;5.75,1.5;1,1;]"..
			"image[4.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
			"listring[current_player;main]"..
			"listring[current_player;craft]"

-- Trash

sfinv.pages["sfinv:crafting"].get = function(self, player, context)
	return sfinv.make_formspec(player, context, [[
			list[current_player;craft;1.75,0.5;3,3;]
			list[current_player;craftpreview;5.75,1.5;1,1;]
			image[4.75,1.5;1,1;sfinv_crafting_arrow.png]
			listring[current_player;main]
			listring[current_player;craft]
			image[5.8,3.7;0.8,0.8;creative_trash_icon.png]
			list[detached:sfinvpptrash;main;5.75,3.6;1,1;]
		]], true)
end

-- 3d armor renders its own inventory... despite sfinv having an option to render
--   it's own formspec... why??
if sfinvpp.mod_3d_armor then
	armor.formspec = "image[2.5,0;2,4;armor_preview]"..
	    default.gui_bg..
	    default.gui_bg_img..
	    default.gui_slots..
	    "label[5,1;"..minetest.formspec_escape("Level")..": armor_level]"..
	    "label[5,1.5;"..minetest.formspec_escape("Heal")..": armor_attr_heal]"
	
	sfinv.pages["3d_armor:armor"].get = function(self, player, context)
		local name = player:get_player_name()
		local formspec = armor:get_armor_formspec(name, true)
		return sfinv.make_formspec(player, context, formspec, true)
	end
end
