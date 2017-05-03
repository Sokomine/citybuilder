
-- founding of a new city
citybuilder.cityadmin_start_city_at = function( pos, owner, city_name )
	-- there can be only one city at a given location
	local city_id = minetest.pos_to_string( pos );
	if( citybuilder.cities[ city_id ] ) then
		return "There is already a sattlement registered at "..tostring(city_id)..".";
	end

	-- players cannot found an infinite number of cities
	local anz = 1;
	for k,v in pairs( citybuilder.cities ) do
		if( v and v.owner and v.owner == owner) then
			anz = anz+1;
		end
	end
	if( anz > citybuilder.max_cities_per_player ) then
		return "You can only have "..tostring( citybuilder.max_cities_per_player ).." cities.";
	end

	-- make sure cities do not overlap
	local city_start_pos = { x=pos.x-math.ceil(citybuilder.min_intercity_distance/2), y=pos.y- 20, z=pos.z-math.ceil(citybuilder.min_intercity_distance/2) };
	local city_end_pos   = { x=pos.x+math.ceil(citybuilder.min_intercity_distance/2), y=pos.y+100, z=pos.z+math.ceil(citybuilder.min_intercity_distance/2) };
	for k,v in pairs( citybuilder.cities ) do
		if( v and v.start_pos and v.end_pos
		  and (math.abs( v.pos.x - pos.x )< citybuilder.min_intercity_distance )
		  and (math.abs( v.pos.z - pos.z )< citybuilder.min_intercity_distance )
		  and (math.abs( v.pos.y - pos.y )< citybuilder.min_intercity_distance )) then
			return "City area would overlap with city at "..tostring( k )..".";
		end
	end

	-- register the new city
	citybuilder.cities[ city_id ] = {
			pos = pos,
			start_pos = city_start_pos,
			end_pos = city_end_pos,
			owner = owner,
			founded = os.time(),
			city_name = city_name,
			wood = "-unkown-",
			buildings = {},
			inhabitants = {} };
	-- save it
	citybuilder.save_data();
	return;
end


citybuilder.cityadmin_get_main_menu_formspec = function( city_id )
	local city_data = citybuilder.cities[ city_id ];
	if( not( city_data )) then
		return "label[0.5,0.2;Error: City has not been founded yet.]";
	end
	return "label[3.5,0.2;City administration]"..
			"label[0.2,1.0;Name of settlement:]"..
				"label[3.5,1.0;"..city_data.city_name.."]"..
				"label[3.5,1.3;founded by "..city_data.owner.."]"..
			"label[0.2,2.0;Wood type used:]"..
				"item_image[3.5,1.75;1,1;"..city_data.wood.."]"..
			"label[0.2,3.0;Number of buildings:]"..
				"label[3.5,3.0;"..citybuilder.city_get_anz_buildings( city_id ).."]"..
				"button[4.0,3.0;2.5,0.5;show_buildings;Show buildings]"..
			"label[0.2,4.0;Number of inhabitants:]"..
				"label[3.5,4.0;"..table.getn( city_data.inhabitants ).."]";

end


citybuilder.cityadmin_on_receive_fields = function( pos, formname, fields, player)
	if( not( pos ) or fields.OK or fields.abort) then
		return;
	end
	local meta = minetest.get_meta( pos );
	-- these values are duplicated in the city datastructure
	local owner     = meta:get_string( "owner" );
	local pname     = player:get_player_name();
	local city_id   = minetest.pos_to_string( pos );
	local city_data = citybuilder.cities[ city_id ];
	local pos_str   = "field[20,20;0.1,0.1;pos2str;Pos;"..city_id.."]";
	local inv = meta:get_inventory();

	local formspec = "size[10,10]"..
			pos_str..
			"label[3,1;City administration]";

	-- most functions need to be limited to the founder of the city
	if( owner ~= pname) then
		formspec = "size[8,6]"..
			pos_str..
			citybuilder.cityadmin_get_main_menu_formspec( city_id )..
			"button_exit[3.5,5;1.0,0.5;abort;Exit]";


	-- the player provided a city name
	elseif( fields.set_city_name and fields.set_city_name ~= "" and fields.new_city_name and fields.new_city_name ~= "") then

		if( not( city_data )) then
			-- check if the city can be founded here
			local error_msg = citybuilder.cityadmin_start_city_at( pos, owner, fields.new_city_name );
			if( error_msg ) then
				minetest.show_formspec( pname, "citybuilder:cityadmin",
					"size[8,2]"..
					"label[0,0.0;Founding of this city failed. Reason:]"..
					"label[0.5,0.4;"..error_msg.."]"..
					"button_exit[3.5,1.2;1,0.5;abort;Exit]");
				return;
			end
		end
		meta:set_string( "city_name", fields.new_city_name );
		meta:set_string( "infotext", fields.new_city_name.." (founded by "..tostring( owner )..") city administrator desk");

		-- store the new name in the citydatastructure
		citybuilder.cities[ city_id ].city_name = fields.new_city_name;
		citybuilder.save_data();

		formspec = "size[6,2]"..
			pos_str..
			"label[0,0.0;Your settlement is now known as:]"..
			"label[1.5,0.7;"..fields.new_city_name.."]"..
			"button[2.5,1.5;1.5,0.5;proceed;Proceed]";


	-- the city needs a name
	elseif( not( city_data ) or fields.rename_city) then
		local city_name = "";
		if( city_data and city_data.city_name ~= "") then
			city_name = city_data.city_name;
		else
			city_name = owner.." City";
		end
		formspec = "size[6,2]"..
			pos_str..
			"label[0,0.0;How shall your settlement be called?]"..
			"label[0,0.7;Name:]"..
			"field[1.5,1;4,0.5;new_city_name;;"..city_name.."]"..
			"button_exit[1.5,1.5;1.5,0.5;abort;Abort]"..
			"button[3.5,1.5;1.5,0.5;set_city_name;Save]";


	-- make the node diggable again by abandoning cities
	elseif( fields.confirm_abandon and fields.abandon_city_name and city_data and fields.abandon_city_name==city_data.city_name ) then

		-- All inventory spaces (saplings, printer, ..) need to be empty
		if( not( inv:is_empty("saplings")) or not( inv:is_empty( "printer_input" )) or not( inv:is_empty( "printer_output"))) then
			formspec = "size[5,2]"..
				"label[0.5,0;Please remove all saplings and ]"..
				"label[0.5,0.5;constructors first!]"..
				"button_exit[2.0,1.3;1.5,0.5;back;Back]";
		-- forbid abandoning of cities that have assigned buildings
		elseif( citybuilder.city_get_anz_buildings( city_id )>0) then
			formspec = "size[5,2]"..
				"label[0.5,0;Please remove all buildings that are]"..
				"label[0.5,0.5;associated with this city first!]"..
				"button_exit[2.0,1.3;1.5,0.5;back;Back]";
		-- ..or those that have inhabitants
		elseif( table.getn( city_data.inhabitants)>0) then
			formspec = "size[5,2]"..
				"label[0.5,0;The city still has some inhabitants.]"..
				"label[0.5,0.5;Get rid of them first!]"..
				"button_exit[2.0,1.3;1.5,0.5;back;Back]";
		else
			-- actually unregister the city from the data structure and make the node diggable
			citybuilder.cities[ city_id ] = nil;
			citybuilder.save_data();
			meta:set_string( "city_name", nil);
			meta:set_string("infotext", "Founding of a city by "..meta:get_string("owner").." (planned)");
			-- return a formspec for confirmation
			formspec = "size[6,2]"..
				"label[0,0;City abandoned. You can now dig the city]"..
				"label[0,0.5;administration desk and use it elsewhere.]"..
				"button_exit[2.0,1.3;1.5,0.5;OK;OK]";
		end

	elseif( fields.abandon ) then
		formspec = "size[8,2.5]"..
			pos_str..
			"label[0,0.0;Do you really want to abandon your city?]"..
			"label[0,0.5;If so, please enter the name of your city below and confirm:]"..
			"label[0,1.0;Name:]"..
			"field[1.5,1.4;4,0.5;abandon_city_name;;]"..
			"button[1.5,1.9;1.5,0.5;back;Abort]"..
			"button[3.5,1.9;3.5,0.5;confirm_abandon;Confirm - really abandon]";


	-- set the type of wood the city will use
	elseif( city_data and (city_data.wood == "" or not(minetest.registered_nodes[city_data.wood]) or fields.change_wood or fields.change_wood_store)) then

		local stack = inv:get_stack("saplings", 1 );
		if( stack and not( stack:is_empty()) and fields.change_wood_store) then
			local sapling_name = stack:get_name();
			for k,v in pairs( replacements_group['wood'].data ) do
				if( v[6]==sapling_name and k ~= city_data.wood and stack:get_count()>=25) then
					-- take the 25 saplings
					inv:remove_item("saplings", stack:get_name().." 25");
					-- set the new wood type and store it in the city data structure
					citybuilder.cities[ city_id ].wood = k;
					citybuilder.save_data();
				end
			end
		end

		local show_wood = "";
		if( city_data.wood and minetest.registered_nodes[ city_data.wood ]) then
			show_wood = "item_image[4.4,1.4;1,1;"..city_data.wood.."]"..
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


	-- show a list of all buildings that belong to the city
	elseif( fields.show_buildings ) then
		formspec = "size[10,10]"..
			pos_str..
			"label[0.2,0.2;Buildings that belong to this settlement:]"..
			"tablecolumns[" ..
				"text,align=center;"..   -- title of the building
				"text,align=center;"..   -- what the building provides
				"text,align=center;"..   -- description of building
				"text,align=center;"..   -- level of the building
				"text,align=center]"..   -- position
                        'table[0.2,0.8;9.0,8.0;form_does_not_exist;';

		for k,v in pairs(city_data.buildings) do
			local building_data = build_chest.building[ citybuilder.mts_path..v.building_name ];
			if( building_data ) then
				formspec = formspec..
					minetest.formspec_escape(building_data.title or building_data.scm or tostring(i))..","..
					minetest.formspec_escape("["..(building_data.provides or "- unknown -").."]")..","..
					minetest.formspec_escape("\""..building_data.descr or "").."\","..
					minetest.formspec_escape("[Level "..(building_data.level or "?").."]")..","..
					minetest.formspec_escape(k)..",";
			end
		end
		formspec = formspec..';]'..
				"button[8.0,9.0;1.0,0.5;back;Back]";


	-- add new buildings (by "printing" blueprints on citybuilder:constructor_blank
	elseif( fields.add_building or fields[ "citybuilder:cityadmin"] or fields.print_building) then
		if( fields.print_building and fields.selected_blueprint) then
			local input_stack  = inv:get_stack("printer_input", 1 );
			local output_stack = inv:get_stack("printer_output", 1 );
			-- is there a blank constructor available which we can configure?
			if( output_stack:is_empty() and inv:contains_item("printer_input", "citybuilder:constructor_blank")) then
				-- take one blank constructor..
				input_stack:take_item(1);
				-- ..and add a properly configured one
				local new_stack = citybuilder.constructor_get_configured_itemstack(
					citybuilder.mts_path..citybuilder.starter_buildings[ tonumber(fields.selected_blueprint) ],
					city_data.owner, city_id, city_data.wood, player );
				-- put the configured constructor in the output field
				output_stack:add_item( new_stack );
				inv:set_stack( "printer_input",  1, input_stack );
				inv:set_stack( "printer_output", 1, output_stack );
			end
		end

		formspec = "size[10,10]"..
			pos_str..
			"label[0.2,0.2;Please select the type of building you want to add:]"..
			"list[current_player;main;0,6.0;8,4;]"..
			"button[8.5,0.0;1.0,0.5;back;Back]"..
				"label[7.8,1.0;Input:]"..
				"list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";printer_input;8.0,1.5;1,1;]"..
				"item_image[9.0,1.5;1,1;citybuilder:constructor_blank]"..
				"label[7.8,3.5;Output:]"..
				"list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";printer_output;8.0,4.0;1,1;]"..
				"item_image[9.0,4.0;1,1;citybuilder:constructor]"..
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
				"field[20,21;0.1,0.1;selected_blueprint;selected_blueprint_row;"..tostring(clicked.row).."]"..
				"button[7.0,2.8;3.0,0.5;print_building;Print selected blueprint]"..
				"label[7.0,5.0;Selected: "..tostring( building_data.title or "-unkown-").."]";
		else
			formspec = formspec..';]';
		end


	-- normal main menu
	else
		formspec = "size[10,6]"..
			pos_str..
			citybuilder.cityadmin_get_main_menu_formspec( city_id )..
				"button[8,1;2.0,0.5;rename_city;Rename city]"..
				"button[8,2;2.0,0.5;change_wood;Change wood]"..
				"button[8,3;2.0,0.5;add_building;Add building]"..
				"button[8,4;2.0,0.5;info_inhabitants;Show details]"..
			"button[0.2,5;2.5,0.5;abandon;Abandon settlement]"..
			"button_exit[8.5,5;1.0,0.5;abort;Exit]";
	end
	minetest.show_formspec( pname, "citybuilder:cityadmin", formspec );
end


minetest.register_node("citybuilder:cityadmin", {
	description = "Desk of the city administrator",
	tiles = {"default_chest_top.png^default_book_written.png", "default_chest_top.png", "default_chest_side.png", -- TODO: needs a better texture
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png^default_tool_diamondshovel.png"},
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
	legacy_facedir_simple = true,

	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5,  0.5-2/16, -0.5, 0.5, 0.5, 0.5}, -- top of the desk
			{-0.5+2/16, -0.5, -0.5, -0.5, 0.5, 0.5}, -- one side
			{ 0.5-2/16, -0.5, -0.5, 0.5, 0.5, 0.5}, -- another side
			{-0.5, 0.5-6/16, -0.5+2/16, 0.5, 0.5, -0.5}, -- front
		},
	},


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
		-- used for turning citybuilder:constructor_blank into configured citybuilder:constructor
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
		if( listname=="printer_input" and (not( stack ) or stack:get_name()~="citybuilder:constructor_blank")) then
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
		if( citybuilder.cities[ minetest.pos_to_string( pos )]) then
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
