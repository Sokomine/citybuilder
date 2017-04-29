
-- citybuilder:blueprint is used to construct the houses at the location
-- which the player selected


-- the citybuilder:blueprint node does hold metadata information;
-- return a new stack with a configured constructor;
citybuilder.constructor_get_configured_itemstack = function( building_name, owner, city_center_pos, wood, player )
	-- the building has to be known
	local building_name = building_name;
	local building_data = build_chest.building[ building_name ];
	if( not( building_name ) or not( building_data )) then
		return;
	end

	-- configure the new item stack holding a configured blueprint
	local item_stack = ItemStack("citybuilder:blueprint 1");
	local stack_meta = item_stack:get_meta();
	local data = stack_meta:to_table().fields;

	-- fallback if no playername is set
	if( not( owner ) or owner == "" ) then
		owner = player:get_player_name();
	end
	data.building_name   = building_name;
	data.owner           = owner;
	data.city_center_pos = city_center_pos;
	data.wood            = wood;
	if( building_data.title and building_data.provides and building_data.size) then
		data.description     = "\""..tostring(building_data.title)..
					"\" (provides "..tostring( building_data.provides )..
					") L "..tostring( building_data.size.x )..
					" x W "..tostring(building_data.size.z)..
					" x H "..tostring(building_data.size.y)..
					" building constructor";
	else
		data.description     = "Building constructor for "..tostring( building_data.scm );
	end
	item_stack:get_meta():from_table({ fields = data });
	return item_stack;
end


-- when digging the player gets a citybuilder:blueprint_blank first; but from the
-- oldmetadata we get in after_dig_node all the necessary information can be
-- obtained and the player will get a citybuilder:blueprint that is set to the
-- correct blueprint and has a nice description for mouseover
citybuilder.constructor_digged = function(pos, oldnode, oldmetadata, player)
	-- TODO: unregister the building from the city data table

	if( not(pos) or not(player)
	  or not( oldmetadata ) or oldmetadata=="nil" or not(oldmetadata.fields)) then
		return;
	end

	-- the digged blank blueprint will be replaced with a properly configured one if possible
	local player_inv = player:get_inventory();
	if( not( player_inv:contains_item("main", "citybuilder:blueprint_blank"))
	  or not( player_inv:room_for_item( "main", "citybuilder:blueprint" ))) then
		return;
	end

	-- get a configured itemstack with metadata
	local item_stack = citybuilder.constructor_get_configured_itemstack(
			oldmetadata.fields.building_name, oldmetadata.fields.owner, oldmetadata.fields.city_center_pos, oldmetadata.fields.wood, player );
	if( not( item_stack )) then
		return;
	end

	-- remove the unconfigured blueprint which was the result of the digging action
	player_inv:remove_item("main", "citybuilder:blueprint_blank 1");
	player_inv:add_item("main", item_stack);
end



-- called in after_place_node
citybuilder.constructor_placed = function( pos, placer, itemstack )
	if( not( pos ) or not( placer ) or not( itemstack )) then
		return;
	end

	-- get itemstack metadata
	local item_meta = itemstack:get_meta();
	local data = item_meta:to_table().fields;

        if( not( data.building_name ) or data.building_name=="" or not( build_chest.building[ data.building_name ])) then
		citybuilder.show_error_msg( placer,
			"This building constructor has not been configured yet. "..
			"Please configure it by using your city administration device.");
		return;
	end

	if( data.owner ~= placer:get_player_name()) then
		citybuilder.show_error_msg( placer,
			"This building constructor belongs to "..tostring( data.owner )..". "..
			"You can't use it. Craft your own one!");
		return;
	end

-- TODO: also check city_center_pos
-- TODO: check if placement is allowed
	local meta = minetest.get_meta( pos );
	meta:set_string( 'owner',           placer:get_player_name());
	meta:set_string( 'building_name',   data.building_name );
	meta:set_string( 'city_center_pos', data.city_center_pos );
	meta:set_string( 'wood',            data.wood );


	-- this takes param2 of the node at the position pos into account (=rotation
	-- of the chest/plot marker/...) and sets metadata accordingly: start_pos,
	-- end_pos, rotate, mirror and replacements
	local start_pos = build_chest.get_start_pos( pos );
	if( not( start_pos ) or not( start_pos.x )) then
		citybuilder.show_error_msg( placer,
				"Error: "..tostring( start_pos ));
		return;
	end

	local formspec = citybuilder.constructor_update( pos, placer, meta, nil, nil );
	minetest.show_formspec( placer:get_player_name(), "citybuilder:constructor", formspec );
end


-- returns the new formspec
citybuilder.constructor_update = function( pos, player, meta, do_upgrade, no_update )
	if( not( meta ) or not( pos ) or not( player )) then
		return;
	end
	local building_name = meta:get_string( 'building_name' );
	local error_msg = nil;
	if( not( building_name ) or building_name == "" or not( build_chest.building[ building_name ] )) then
		error_msg = "Unkown building \""..tostring( building_name ).."\".";
	elseif( no_update ) then
		-- do nothing here
	else
		-- apply wood replacements
		local replacements = {};
		local wood = meta:get_string("wood");
		if( wood and wood ~= "" and replacements_group['wood'].data[ wood ] and wood ~= "default:wood") then
			for i,v in ipairs( replacements_group['wood'].data[ "default:wood"] ) do
				local new_node = replacements_group['wood'].data[ wood ][ i ];
				if( v and new_node and minetest.registered_nodes[ v ] and minetest.registered_nodes[ new_node ]) then
					table.insert( replacements, {v, new_node});
				end
			end
		end

		-- the place_building_from_file function will set these values
		meta:set_int( "nodes_to_dig", -1 );
		meta:set_int( "nodes_to_place", -1 );
		-- actually place dig_here-indicators and special scaffolding
		error_msg = handle_schematics.place_building_from_file(
			minetest.deserialize(meta:get_string( "start_pos")),
			minetest.deserialize(meta:get_string( "end_pos")),
			building_name,
			replacements,
		        meta:get_string("rotate"),
			build_chest.building[ building_name ].axis,
			nil, -- no mirror; meta:get_int("mirror"),
			-- no_plotmarker, keep_ground, scaffolding_only, plotmarker_pos
			1, false, true, pos );
	end

	local formspec = "size[9,7]"..
			"list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";needed;0,2;8,5;]"..
			"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]"..
			"button_exit[3.0,0.7;2.5,0.5;remove_indicators;Remove scaffolding]"..
			"button_exit[6.0,0.7;1.2,0.5;preview;Preview]"..
			"button_exit[7.5,0.7;1,0.5;OK;Exit]";
	if( error_msg ) then
		return formspec..
			"label[0,0.1;Error: "..tostring( error_msg ).."]";
	end

	local need_to_dig   = meta:get_int( "nodes_to_dig" );
	local need_to_place = meta:get_int( "nodes_to_place" );

	-- if the building is not yet finished
	if( need_to_dig ~= 0 or need_to_place ~= 0 or not( build_chest.building[ building_name ].citybuilder)) then
		return formspec..
			"label[0,0.1;Status: Need to dig "..tostring( need_to_dig ).." and place "..tostring( need_to_place ).." nodes.]"..
			"button_exit[0.5,0.7;2,0.5;update;Update status]";
	end

	-- set the level of the (completed) building
	meta:set_int( "citybuilder_level", build_chest.building[ building_name ].level+1 );
	meta:set_int( "complete", 1 );

	if( build_chest.building[ building_name ].upgrade_to ) then

		-- only the owner/founder can do upgrades
		if( not( citybuilder.can_access_inventory( pos, player))) then
			return formspec..
				"label[0,0.1;Only the founder of this city may upgrade buildings.]";
		end

		-- TODO: check if upgrade is allowed
		local upgrade_possible_to = build_chest.building[ building_name ].upgrade_to;
		local descr = upgrade_possible_to;
		if( upgrade_possible_to
		  and build_chest.building[ citybuilder.mts_path..upgrade_possible_to ]
		  and build_chest.building[ citybuilder.mts_path..upgrade_possible_to ].descr ) then
			descr = build_chest.building[ citybuilder.mts_path..upgrade_possible_to ].descr;
		end

		if( not( do_upgrade )) then
			return formspec..
				"label[0,0.1;Info: Upgrade \""..descr.."\" (level "..
					tostring( build_chest.building[ citybuilder.mts_path..upgrade_possible_to ].level )..") available.]"..
				"button_exit[0.5,0.7;2,0.5;upgrade;Upgrade now]";
		end

		meta:set_string( 'building_name', citybuilder.mts_path..upgrade_possible_to );
		-- call the function recursively once in order to update
		return citybuilder.constructor_update( pos, player, meta, nil, nil );
	end
	return formspec..
		"label[0,0.1;Congratulations! The highest upgrade has been reached.]";
end




citybuilder.constructor_on_receive_fields = function(pos, formname, fields, player)
	if( not( pos ) or fields.OK) then
		return;
	end
	local meta = minetest.get_meta( pos );

	if( fields.remove_indicators ) then
		handle_schematics.abort_project_remove_indicators( meta );
		return;
	end

	-- most functions are accessible to all players; only upgrades are limited to the owner
	local formspec = "";
	if( fields.preview and not( fields.end_preview )) then
		if( fields.preview == "Preview" ) then
			fields.preview = "front";
		end
		local building_name = meta:get_string( 'building_name' );
		formspec = "size[10,10]"..
			"label[3,1;Preview]"..
			"button[7,1;2.5,0.5;end_preview;Back to main menu]"..
			"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]"..
			build_chest.preview_image_formspec( building_name, {}, fields.preview);
	else
		formspec = citybuilder.constructor_update( pos, player, meta, fields.upgrade, not(fields.update) );
	end
	minetest.show_formspec( player:get_player_name(), "citybuilder:constructor", formspec );
end


minetest.register_node("citybuilder:blueprint", {
	description = "Blueprint for a house",
	tiles = {"default_chest_side.png", "default_chest_top.png", "default_chest_side.png", -- TODO: a universal texture would be better
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png^beds_bed.png"},
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2,not_in_creative_inventory=1},
	legacy_facedir_simple = true,
	-- constructors are configured; stacking would not be a good idea
	stack_max = 1,
	-- when digging, return unconfigured blueprint; but: in after_dig_node it is exchanged for a configured one
	drop = "citybuilder:blueprint_blank",

        after_place_node = function(pos, placer, itemstack)
		citybuilder.constructor_placed( pos, placer, itemstack );
        end,
        on_receive_fields = function( pos, formname, fields, player )
           return citybuilder.constructor_on_receive_fields(pos, formname, fields, player);
        end,
        allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
                if from_list=="needed" or to_list=="needed" then return 0 end
		if( not( citybuilder.can_access_inventory( pos, player))) then
			return false;
		end
                return count
        end,
        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
                if listname=="needed" then return 0 end
		if( not( citybuilder.can_access_inventory( pos, player))) then
			return false;
		end
                return stack:get_count()
        end,
        allow_metadata_inventory_take = function(pos, listname, index, stack, player)
                if listname=="needed" then return 0 end
		if( not( citybuilder.can_access_inventory( pos, player))) then
			return false;
		end
                return stack:get_count()
        end,

        can_dig = function(pos,player)
            local meta          = minetest.get_meta( pos );
            local inv           = meta:get_inventory();
            local owner_name    = meta:get_string( 'owner' );
            local building_name = meta:get_string( 'building_name' );
            local name          = player:get_player_name();

		if( not( meta ) or not( owner_name )) then
			return true;
		end
		if( owner_name ~= name and owner_name ~= "") then
			minetest.chat_send_player(name, "This building chest belongs to "..tostring( owner_name )..". You can't take it.");
			return false;
		end

		local level = meta:get_int( "citybuilder_level" );
		if( level and level > 0 ) then
			minetest.chat_send_player(name, "This chest has spawned a building and cannot be digged.");
			return false;
		end
		-- TODO: only allow aborting a project if level 0 has not been completed yet
		-- TODO: unregister the building with the townhall
		handle_schematics.abort_project_remove_indicators( meta );
		return true;
        end,

	-- handle formspec manually - not via meta:set_string("formspec") as it is very dynamic
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		citybuilder.constructor_on_receive_fields(pos, "citybuilder:constructor", {}, clicker );
		return itemstack;
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		return citybuilder.constructor_digged(pos, oldnode, oldmetadata, digger);
	end
})


-- helper item; blank blueprint constructors cannot be placed
minetest.register_craftitem("citybuilder:blueprint_blank", {
	description = "Blank blueprint constructor",
	inventory_image = "default_paper.png^[transformFX",
        groups = {},
})

minetest.register_craft({
	output = "citybuilder:blueprint_blank",
	recipe = {
		{"default:paper", "default:paper", "default:paper"},
		{"default:paper", "default:paper", "default:paper"},
		{"", "default:chest", "default:sign_wall"}
	}
})
