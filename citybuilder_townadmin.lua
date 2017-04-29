
-- only level 0 buildings are available at the beginning; all other buildings
-- can only be obtained through upgrades of said level 0 buildings
citybuilder.starter_buildings = {};

for i,v in ipairs( citybuilder.buildings ) do
	-- this is a building that belongs to the citybuilder mod
	v.citybuilder = 1;
	-- register the building so that handle_schematics can analyze the blueprint and keep it ready
	build_chest.add_building( citybuilder.mts_path..v.scm, v );
	-- create preview images, statistics etc
	build_chest.read_building( citybuilder.mts_path..v.scm, v );
	-- add the building to the build chest
	build_chest.add_entry( {'main','mods', 'citybuilder', v.provides, v.scm, citybuilder.mts_path..v.scm});
	-- there has to be a first building in each series which does not require any predecessors;
	-- it will be offered as something the player can build
	-- (upgrades are then available at the particular building)
	if( not( v.requires )) then
		table.insert( citybuilder.starter_buildings, v.scm );
	end	
end

-- print("[citybuilder] Available starter buildings: "..minetest.serialize( citybuilder.starter_buildings ));



citybuilder.cityadmin_on_receive_fields = function( pos, formname, fields, player)
	if( not( pos ) or fields.OK or fields.abort) then
		return;
	end
	local meta = minetest.get_meta( pos );
	local owner     = meta:get_string( "owner" );
	local founded   = meta:get_string( "founded");
	local city_name = meta:get_string( "city_name" );
	local wood      = meta:get_string( "wood");
	local pname     = player:get_player_name();
	local pos_str   = "field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]";

	local formspec = "size[10,10]"..
			pos_str..
			"label[3,1;City administration device]";

	-- most functions need to be limited to the founder of the city
	if( owner ~= pname) then
		formspec = formspec.."label[1,3;TODO: Show overview for other people than the founder.]"; -- TODO

	-- the city needs a name
	elseif( not( founded ) or founded == "" or not( city_name ) or city_name == "" or fields.change_name or fields.rename_city) then
		if( not( city_name ) or city_name == "" ) then
			city_name = owner.." City";
		end
		formspec = "size[6,2]"..
			pos_str..
			"label[0,0.0;How shall your settlement be called?]"..
			"label[0,0.7;Name:]"..
			"field[1.5,1;4,0.5;new_city_name;;"..city_name.."]"..
			"button_exit[1.5,1.5;1.5,0.5;abort;Abort]"..
			"button[3.5,1.5;1.5,0.5;set_city_name;Save]";

	-- the player provided a city name
	elseif( fields.set_city_name and fields.set_city_name ~= "" and fields.new_city_name and fields.new_city_name ~= "") then

		if( not( founded ) or founded=="" ) then
			-- TODO: check if the city can be founded here
			meta:set_string( "founded", os.time());
		end
		if( not( fields.new_city_name) or fields.new_city_name == "" ) then
			fields.new_city_name = city_name;
		end
		meta:set_string( "city_name", fields.new_city_name );
		meta:set_string( "infotext", fields.new_city_name.." (founded by "..tostring( owner )..")");

		formspec = "size[6,2]"..
			pos_str..
			"label[0,0.0;Your settlement is now known as:]"..
			"label[1.5,0.7;"..fields.new_city_name.."]"..
			"button[2.5,1.5;1.5,0.5;proceed;Proceed]";


	elseif( not( wood ) or wood=="" or fields.change_wood or fields.change_wood_store) then

		local inv = meta:get_inventory();
		local stack = inv:get_stack("saplings", 1 );
		if( stack and not( stack:is_empty()) and fields.change_wood_store) then
			local sapling_name = stack:get_name();
			for k,v in pairs( replacements_group['wood'].data ) do
				if( v[6]==sapling_name and k ~= wood and stack:get_count()>=25) then
					-- set the new wood type
					wood = k;
					-- take the 25 saplings
					inv:remove_item("saplings", stack:get_name().." 25");
					-- store the new wood type
					meta:set_string( "wood", wood );
				end
			end
		end

		local show_wood = "";
		if( wood and minetest.registered_nodes[ wood ]) then
			show_wood = "item_image[4.4,1.4;1,1;"..wood.."]"..
				"button_exit[6.0,1.0;1.5,0.5;back;Back]";
		end

		formspec = "size[8,7.5]"..
			pos_str..
			"label[0,0.0;Which type of trees shall your lumberjacks use?]"..
			"label[0.0,0.5;Please insert 25 saplings of the desired type here:]"..
			"label[1.4,1.4;Saplings:]"..
			"list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";saplings;2.5,1.2;1,1;]"..
			"label[4.0,1.0;Current wood:]"..
			show_wood..
			"button[6.0,2.0;1.5,0.5;change_wood_store;Save]"..
			"list[current_player;main;0,3.0;8,4;]";


	elseif( fields.add_building or fields[ "citybuilder:cityadmin"]) then
		formspec = "size[10,10]"..
			pos_str..
			"label[0.2,0.2;Please select the type of building you want to add:]"..
			"list[current_player;main;0,6.0;8,4;]"..
			"button[8.5,0.0;1.0,0.5;back;Back]"..
				"label[7.8,1.0;Input:]"..
				"list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";printer_input;8.0,1.5;1,1;]"..
				"item_image[9.0,1.5;1,1;citybuilder:blueprint_blank]"..
				"label[7.8,3.5;Output:]"..
				"list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";printer_output;8.0,4.0;1,1;]"..
				"item_image[9.0,4.0;1,1;citybuilder:blueprint]"..
			"tablecolumns[" ..
				"text,align=center;"..   -- description of building
				"text,align=center]"..   -- what the building provides
                        'table[0.2,0.8;6.0,5.0;'..formname..';';


		for i,v in ipairs( citybuilder.starter_buildings ) do
			local building_data = build_chest.building[ citybuilder.mts_path..v ];
			formspec = formspec..
					(building_data.title or building_data.scm or tostring(i))..","..
					minetest.formspec_escape("["..(building_data.provides or "- unknown -").."]")..",";
		end

		local clicked = minetest.explode_table_event( fields[ "citybuilder:cityadmin"] );
		if( clicked and clicked.row and clicked.row > 0 and citybuilder.starter_buildings[ clicked.row ]) then
			local building_data = build_chest.building[ citybuilder.mts_path..citybuilder.starter_buildings[ clicked.row ] ];
			formspec = formspec..';'..tostring(clicked.row)..']'..
--TODO: store what was selected
				"button[7.0,2.8;3.0,0.5;print_building;Print selected blueprint]"..
				"label[7.0,5.0;Selected: "..tostring( building_data.title or "-unkown-").."]";
		else
			formspec = formspec..';]';
		end


	-- normal main menu
	else
		local anz_buildings = 0; -- TODO
		local anz_inhabitants = 0; -- TODO
		formspec = "size[10,6]"..
			pos_str..
			"label[3.5,0.2;City administration]"..
			"label[0.2,1.0;Name of settlement:]"..
				"label[3.5,1.0;"..city_name.."]"..
				"button[8,1;2.0,0.5;rename_city;Rename city]"..
			"label[0.2,2.0;Wood type used:]"..
				"item_image[3.5,1.75;1,1;"..wood.."]"..
				"button[8,2;2.0,0.5;change_wood;Change wood]".. -- TODO: actually use the wooden replacements
			"label[0.2,3.0;Number of buildings:]"..
				"label[3.5,3.0;"..tostring( anz_buildings ).."]"..
				"button[8,3;2.0,0.5;add_building;Add building]".. -- TODO
			"label[0.2,4.0;Number of inhabitants:]"..
				"label[3.5,4.0;"..tostring( anz_inhabitants ).."]"..
				"button[8,4;2.0,0.5;info_inhabitants;Show details]".. -- TODO
			"button[0.2,5;2.5,0.5;abandon;Abandon settlement]"..
			"button_exit[8.5,5;1.0,0.5;abort;Exit]";
	end
	minetest.show_formspec( "singleplayer", "citybuilder:cityadmin", formspec );
end


minetest.register_node("citybuilder:cityadmin", {
	description = "City administration device",
	tiles = {"default_chest_side.png", "default_chest_top.png", "default_chest_side.png", -- TODO: needs a better texture
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png^default_tool_diamondshovel.png"},
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
	legacy_facedir_simple = true,

	after_place_node = function(pos, placer, itemstack)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name() or "");
		meta:set_string("infotext", "Founding of a city by "..meta:get_string("owner").." (planned)");
        end,

        on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", "")
		local inv = meta:get_inventory()
		-- used for determining which wood type the village will use
		inv:set_size("saplings", 1 * 1)
		-- used for turning citybuilder:blueprint_blank into configured citybuilder:blueprint
		inv:set_size("printer_input", 1 * 1)
		inv:set_size("printer_output", 1 * 1)
        end,

        allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if( not( citybuilder.can_access_inventory( pos, player))) then
			return 0;
		end
                return count
        end,
        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if( not( citybuilder.can_access_inventory( pos, player))) then
			return 0;
		end
		if( listname=="printer_output") then
			return 0;
		end
		if( listname=="printer_input" and not( stack ) or stack:get_name()~="citybuilder:blueprint_blank") then
			return 0;
		end
                return stack:get_count()
        end,
        allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if( not( citybuilder.can_access_inventory( pos, player))) then
			return 0;
		end
                return stack:get_count()
        end,

        can_dig = function(pos,player)
		local meta          = minetest.get_meta( pos );
		local inv           = meta:get_inventory();
		local owner_name    = meta:get_string( "owner" );
		local name          = player:get_player_name();
		local founded       = meta:get_string( "founded" );

		if( not( meta ) or not( owner_name )) then
			return true;
		end
		-- only the owner can dig
		if( owner_name ~= name and owner_name ~= "") then
			minetest.chat_send_player(name,
				"This city administration device belongs to "..tostring( owner_name )..
				". You can't take it.");
			return false;
		end

		-- cities that have been founded cannot be destroyed by digging the node
		if( founded and founded ~= "" ) then
			minetest.chat_send_player(name,
				"This city has been founded already. If you want to abandon it, please "..
				"select the appropriate entry in the menu first.");
			return false;
		end

		return true;
        end,

	-- handle formspec manually - not via meta:set_string("formspec") as it is very dynamic
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		citybuilder.cityadmin_on_receive_fields(pos, "citybuilder:cityadmin", {}, clicker );
		return itemstack;
	end,
})


minetest.register_craft({
	output = "citybuilder:cityadmin",
	recipe = {
		{"default:diamondblock", "default:diamondblock", "default:diamondblock"},
		{"default:diamondblock", "default:diamondblock", "default:diamondblock"},
		{"default:diamondblock", "default:diamondblock", "default:diamondblock"},
	}
})
