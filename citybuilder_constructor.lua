
-- citybuilder:constructor is used to construct the houses at the location
-- which the player selected


-- the citybuilder:constructor node does hold metadata information;
-- return a new stack with a configured constructor;
citybuilder.constructor_get_configured_itemstack = function( building_name, owner, city_center_pos, wood, player )
	-- the building has to be known
	local building_name = building_name;
	local building_data = build_chest.building[ building_name ];
	if( not( building_name ) or not( building_data )) then
		return;
	end

	-- configure the new item stack holding a configured constructor
	local item_stack = ItemStack("citybuilder:constructor 1");
	local stack_meta = item_stack:get_meta();
	local data = stack_meta:to_table().fields;

	-- fallback if no playername is set
	if( not( owner ) or owner == "" ) then
		owner = player:get_player_name();
	end
	data.building_name   = building_data.scm;
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


-- when digging the player gets a citybuilder:constructor_blank first; but from the
-- oldmetadata we get in after_dig_node all the necessary information can be
-- obtained and the player will get a citybuilder:constructor that is set to the
-- correct blueprint and has a nice description for mouseover
citybuilder.constructor_digged = function(pos, oldnode, oldmetadata, player)
	-- unregister the building from the city data table
	if( oldmetadata and pos ) then
		-- no matter which city did hold that building - it gets removed
		citybuilder.city_delete_building( minetest.pos_to_string( pos ));
	end

	if( not(pos) or not(player)
	  or not( oldmetadata ) or oldmetadata=="nil" or not(oldmetadata.fields)) then
		return;
	end

	-- the digged blank constructor will be replaced with a properly configured one if possible
	local player_inv = player:get_inventory();
	if( not( player_inv:contains_item("main", "citybuilder:constructor_blank"))
	  or not( player_inv:room_for_item( "main", "citybuilder:constructor" ))) then
		return;
	end

	-- get a configured itemstack with metadata
	local item_stack = citybuilder.constructor_get_configured_itemstack(
			oldmetadata.fields.building_name, oldmetadata.fields.owner, oldmetadata.fields.city_center_pos, oldmetadata.fields.wood, player );
	if( not( item_stack )) then
		return;
	end

	-- remove the unconfigured constructor which was the result of the digging action
	player_inv:remove_item("main", "citybuilder:constructor_blank 1");
	player_inv:add_item("main", item_stack);
end


-- helper function for citybuilder.constructor_on_place(..)
citybuilder.constructor_clear_meta = function( meta )
	meta:set_string( 'owner',           nil);
	meta:set_string( 'building_name',   nil);
	meta:set_string( 'city_center_pos', nil);
	meta:set_string( 'wood',            nil);
	meta:set_string( 'start_pos',       nil);
	meta:set_string( 'end_pos',         nil);
	meta:set_string( 'rotate',          nil);
	meta:set_int(    'mirror',          nil);
	meta:set_string( 'replacements',    nil);
end


-- the metadata might not fit the stored data; set it to the stored data
citybuilder.constructor_set_meta_to_stored_data = function( pos, stored_building )
	local meta = minetest.get_meta( pos );
	-- set metadata according to what we have stored
	meta:set_string( 'owner',           citybuilder.cities[ stored_building.city_id ].owner);
	meta:set_string( 'building_name',   citybuilder.mts_path..stored_building.building_name);
	meta:set_string( 'city_center_pos', stored_building.city_id );
	meta:set_string( 'wood',            stored_building.wood );
	meta:set_string( 'mirror',          stored_building.mirror );
	meta:set_string( 'rotate',          stored_building.rotate );
	meta:set_string( 'start_pos',       minetest.serialize(stored_building.start_pos ));
	meta:set_string( 'end_pos',         minetest.serialize(stored_building.end_pos ));
end


-- check if the constructor can be placed here; place it if possible
citybuilder.constructor_on_place = function( itemstack, placer, pointed_thing, mode )

	if( placer == nil or pointed_thing == nil) then
		return itemstack;
	end
	local pname = placer:get_player_name();
	--minetest.chat_send_player( pname, "You USED this on "..minetest.serialize( pointed_thing )..".");

	if( pointed_thing.type ~= "node" ) then
		return itemstack; -- no node
	end

	local pos  = minetest.get_pointed_thing_position( pointed_thing, mode );
	local node = minetest.env:get_node_or_nil( pos );
	--minetest.chat_send_player( pname, "  Target node: "..minetest.serialize( node ).." at pos "..minetest.serialize( pos )..".");
	if( node == nil or pos == nil) then
		return itemstack; -- node not yet loaded
	end

	-- get itemstack metadata
	local item_meta = itemstack:get_meta();
	local data = item_meta:to_table().fields;

        if( not( data ) or not( data.building_name ) or data.building_name=="") then
		citybuilder.show_error_msg( placer,
			"This building constructor has not been configured yet. "..
			"Please configure it by using the desk of the city administrator.");
		return itemstack;
	end
	local full_building_name = citybuilder.mts_path..data.building_name;
	local building_data = build_chest.building[ full_building_name ];
	if( not( building_data)) then
		citybuilder.show_error_msg( placer,
			"The building this constructor has been configured for is no "..
			"longer available. Old building: \""..tostring( data.building_name ).."\".");
		return itemstack;
	end

	if( data.owner ~= pname) then
		citybuilder.show_error_msg( placer,
			"This building constructor belongs to "..tostring( data.owner )..". "..
			"You can't use it. Craft your own one!");
		return itemstack;
	end

	if( not( data.city_center_pos ) or not( citybuilder.cities[ data.city_center_pos ])) then
		citybuilder.show_error_msg( placer,
			"This constructor is configured for a (no longer?) existing city at "..
			tostring( data.city_center_pos )..". It cannot be used anymore.");
		return itemstack;
	end

	-- the data structure might believe that there is a configured constructor here, but it might
	-- have been removed by other means (WorldEdit etc.) in the meantime
	local stored_building = citybuilder.city_get_building_at( pos );
	if( stored_building) then
		-- place the node with correct param2
		minetest.set_node( pos, {name="citybuilder:constructor", param2=stored_building.param2});
		-- set metadata accordingly
		citybuilder.constructor_set_meta_to_stored_data( pos, stored_building );
		-- tell the player
		minetest.chat_send_player( pname, "The constructor here had gone missing. It has been replaced.");
		-- show the formspec
		local formspec = citybuilder.constructor_update( pos, placer, meta, nil, nil );
		minetest.show_formspec( pname, "citybuilder:constructor", formspec );
		-- do not consume this constructor as we are just replacing a missing one
		return itemstack;
	end


	local city_data = citybuilder.cities[ data.city_center_pos ];

	-- buildings have to be withhin a reasonable distance of the city administration desk
	local city_center_pos = citybuilder.cities[ data.city_center_pos ].pos;
	if( not( city_data.start_pos )
	  or not( city_data.end_pos )
	  or not( citybuilder.pos_is_inside( pos, city_data.start_pos, city_data.end_pos ))) then
		citybuilder.show_error_msg( placer,
			"This location is too far away form the city center at "..
			data.city_center_pos..
			". Please place this constructor closer to your city administration desk.");
		return itemstack;
	end


	-- is6d is false (4 values are sufficient)
	local param2 = core.dir_to_facedir(placer:get_look_dir(), false);
	-- place the node
	minetest.set_node( pos, {name="citybuilder:constructor", param2=param2});

	-- NOTE: We use and set metadata here even though we have not placed the node itshelf yet!
	local meta = minetest.get_meta( pos );
	meta:set_string( 'owner',           pname);
	meta:set_string( 'building_name',   full_building_name );
	meta:set_string( 'city_center_pos', data.city_center_pos );
	meta:set_string( 'wood',            data.wood );

	-- this takes param2 of the node at the position pos into account (=rotation
	-- of the chest/plot marker/...) and sets metadata accordingly: start_pos,
	-- end_pos, rotate, mirror and replacements
	local start_pos = build_chest.get_start_pos( pos, full_building_name, param2 );
	if( not( start_pos ) or not( start_pos.x )) then
		-- clean up the metadata since we will not place a node there
		citybuilder.constructor_clear_meta( meta );
		-- remove the node as well
		minetest.set_node( pos, {name="air"});
		citybuilder.show_error_msg( placer,
			"Error: "..tostring( start_pos ));
		return itemstack;
	end


	-- make sure there is no overlap with other buildings
	local end_pos = minetest.deserialize( meta:get_string('end_pos'));
	for k,v in pairs( city_data.buildings) do
		if( v and v.start_pos and v.end_pos
		  -- no end corner of the new building can be inside that of the old one here
		  and( citybuilder.pos_is_inside( {x=start_pos.x, y=start_pos.y, z=start_pos.z}, v.start_pos, v.end_pos )
		    or citybuilder.pos_is_inside( {x=start_pos.x, y=start_pos.y, z=end_pos.z  }, v.start_pos, v.end_pos )
		    or citybuilder.pos_is_inside( {x=start_pos.x, y=end_pos.y,   z=start_pos.z}, v.start_pos, v.end_pos )
		    or citybuilder.pos_is_inside( {x=start_pos.x, y=end_pos.y,   z=end_pos.z  }, v.start_pos, v.end_pos )
		    or citybuilder.pos_is_inside( {x=end_pos.x,   y=start_pos.y, z=start_pos.z}, v.start_pos, v.end_pos )
		    or citybuilder.pos_is_inside( {x=end_pos.x,   y=start_pos.y, z=end_pos.z  }, v.start_pos, v.end_pos )
		    or citybuilder.pos_is_inside( {x=end_pos.x,   y=end_pos.y,   z=start_pos.z}, v.start_pos, v.end_pos )
		    or citybuilder.pos_is_inside( {x=end_pos.x,   y=end_pos.y,   z=end_pos.z  }, v.start_pos, v.end_pos )
		  -- no end corner of the old building can be inside the volume of the new building
		    or citybuilder.pos_is_inside( {x=v.start_pos.x, y=v.start_pos.y, z=v.start_pos.z}, start_pos, end_pos )
		    or citybuilder.pos_is_inside( {x=v.start_pos.x, y=v.start_pos.y, z=v.end_pos.z  }, start_pos, end_pos )
		    or citybuilder.pos_is_inside( {x=v.start_pos.x, y=v.end_pos.y,   z=v.start_pos.z}, start_pos, end_pos )
		    or citybuilder.pos_is_inside( {x=v.start_pos.x, y=v.end_pos.y,   z=v.end_pos.z  }, start_pos, end_pos )
		    or citybuilder.pos_is_inside( {x=v.end_pos.x,   y=v.start_pos.y, z=v.start_pos.z}, start_pos, end_pos )
		    or citybuilder.pos_is_inside( {x=v.end_pos.x,   y=v.start_pos.y, z=v.end_pos.z  }, start_pos, end_pos )
		    or citybuilder.pos_is_inside( {x=v.end_pos.x,   y=v.end_pos.y,   z=v.start_pos.z}, start_pos, end_pos )
		    or citybuilder.pos_is_inside( {x=v.end_pos.x,   y=v.end_pos.y,   z=v.end_pos.z  }, start_pos, end_pos ))) then

			citybuilder.constructor_clear_meta( meta );
			minetest.set_node( pos, {name="air"});
			citybuilder.show_error_msg( placer,
				"Error: Overlapping with building project at "..minetest.pos_to_string( v.pos ));
			return itemstack;
		end
	end

	-- register the building in the citybuilder.cities data structure
	citybuilder.city_add_building( data.city_center_pos,
		{ pos = pos, start_pos = start_pos, end_pos = end_pos, building_name = full_building_name,
		  rotate = meta:get_string("rotate"), mirror = meta:get_string("mirror"), wood = data.wood, param2 = param2 });

	-- prepare inventory space
	local inv = meta:get_inventory();
	inv:set_size("needed", 8*5);
	-- consume the placed constructor
	itemstack:take_item(1);

	local formspec = citybuilder.constructor_update( pos, placer, meta, nil, nil );
	minetest.show_formspec( pname, "citybuilder:constructor", formspec );

	return itemstack;
end



-- helper function
citybuilder.get_wood_replacements = function( wood, replacements )
	if( not( wood ) or wood == "" or not( replacements_group['wood'].data[ wood ]) or wood == "default:wood") then
		return replacements;
	end
	for i,v in ipairs( replacements_group['wood'].data[ "default:wood"] ) do
		local new_node = replacements_group['wood'].data[ wood ][ i ];
		if( v and new_node and minetest.registered_nodes[ v ] and minetest.registered_nodes[ new_node ]) then
			table.insert( replacements, {v, new_node});
		end
	end
	return replacements;
end


-- returns the new formspec
citybuilder.constructor_update = function( pos, player, meta, do_upgrade, no_update )
	if( not( meta ) or not( pos ) or not( player )) then
		return;
	end
-- TODO: handle digging in a better way
	-- refuse update of constructors in ready-to-dig-mode
	local level = meta:get_int( "citybuilder_level" );
	if( level < -1 ) then
		return;
	end

	local pname = player:get_player_name();

	-- compare metadata with stored data - they ought to be consistent

	-- get the data from the citybuilder.cities data structure
	local stored_building = citybuilder.city_get_building_at( pos );
	local city_center_pos = meta:get_string( 'city_center_pos');
	-- the data stored in the cities datastructure is considered the valid one because
	-- that data determines which upgrades are possible
	if( stored_building ) then
		-- make sure the metadata is up to date
		citybuilder.constructor_set_meta_to_stored_data( pos, stored_building );

	-- the building was lost somehow, but the city still exists; read metadata and restore city building data from it
	elseif( city_center_pos and citybuilder.cities[ city_center_pos ]) then
		local node = minetest.get_node( pos );
		citybuilder.city_add_building( city_center_pos, -- this is the city_id
			{ pos = pos,
			  building_name = meta:get_string("building_name"),
			  start_pos = minetest.deserialize( meta:get_string('start_pos')),
			  end_pos = minetest.deserialize( meta:get_string('end_pos')),
			  rotate = meta:get_string("rotate"),mirror = meta:get_string("mirror"),
			  wood = meta:get_string("wood"), param2 = param2 });
		minetest.chat_send_player( pname, "Adding this building back to the city. It was missing due to an error.");
	-- if the city is gone, show error message and abort
	else
		minetest.chat_send_player( pname, "Error: The city this building belongs to does not exist.");
		return;
	end


	-- update status (set dig_here indicators, place scaffolding, check how many nodes need to be digged etc.)
	local building_name = citybuilder.mts_path..stored_building.building_name;
	local error_msg = nil;
	if( not( building_name ) or building_name == "" or not( build_chest.building[ building_name ] )) then
		error_msg = "Unkown building \""..tostring( building_name ).."\".";
	elseif( no_update ) then
		-- do nothing here
	else
		-- apply wood replacements
		local replacements = citybuilder.get_wood_replacements( stored_building.wood, {} );

		-- the place_building_from_file function will set these values
		meta:set_int( "nodes_to_dig", -1 );
		meta:set_int( "nodes_to_place", -1 );
		-- prepare the inventory
		local inv = meta:get_inventory();
		inv:set_size("needed", 8*5);
		-- actually place dig_here-indicators and special scaffolding
		error_msg = handle_schematics.place_building_from_file(
			stored_building.start_pos, --minetest.deserialize(meta:get_string( "start_pos")),
			stored_building.end_pos,   --minetest.deserialize(meta:get_string( "end_pos")),
			building_name,
			replacements,
		        stored_building.rotate, -- meta:get_string("rotate"),
			build_chest.building[ building_name ].axis,
			nil, -- no mirror; meta:get_int("mirror"),
			-- no_plotmarker, keep_ground, scaffolding_only, plotmarker_pos
			1, false, true, pos );
	end

	-- show error message if any occoured
	if( error_msg ) then
		return "size[9,2]"..
			"label[0,0.1;Error: "..tostring( error_msg ).."]"..
			"button_exit[4.0,1.2;1,0.5;OK;OK]";
	end




	local building_data = build_chest.building[ building_name ];
	local city_data = citybuilder.cities[ stored_building.city_id ];
	-- show main menu; provide some information about this building project
	local formspec = "size[9,9]"..
			"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]"..

			"button_exit[6.0,8.0;3,0.5;OK;Exit]"..

			"label[1.0,1.5;This is a \""..minetest.formspec_escape( building_data.title or building_data.scm ).."\"]"..
			"label[1.5,2.0;Description: "..minetest.formspec_escape( building_data.descr or " - no description available - ").."]"..
			"label[1.5,2.5;Provides "..( building_data.provides or " - nothing - ")..
					minetest.formspec_escape(" [Level "..tostring( building_data.level ).."]").."]"..

			"label[1.0,6.0;Belongs to settlement:]"..
			"label[1.5,6.5;"..minetest.formspec_escape( city_data.city_name or "-?-").."]"..
			"label[1.5,7.0;located at "..tostring( stored_building.city_id or "-?-").."]"..
			"label[1.5,7.5;founded by: "..minetest.formspec_escape( city_data.owner or "-?-").."]";

	local upgrade_possible_to = building_data.upgrade_to;
	if( upgrade_possible_to ) then
		local upgrade_data = build_chest.building[ citybuilder.mts_path..upgrade_possible_to ];
		formspec = formspec..
			"label[1.5,5.0;\""..minetest.formspec_escape( upgrade_data.title or building_data.scm or "-?-").."\"]"..
			"label[1.5,5.5;Description: "..minetest.formspec_escape( upgrade_data.descr or " - no description available - ").."]";
	else
		formspec = formspec..
			"label[1.0,4.5;No upgrades available.]";
	end

	-- store these values in the city data structure
	stored_building.nodes_to_dig   = meta:get_int( "nodes_to_dig" );
	stored_building.nodes_to_place = meta:get_int( "nodes_to_place" );

-- TODO: show requirements, inh(abitants), worker, children, needs_worker, job (those are potential inhabitants)
-- TODO: show real inhabitants if there are any

	-- if the building is not yet finished
	if( stored_building.nodes_to_dig ~= 0 or stored_building.nodes_to_place ~= 0 or not( building_data.citybuilder)) then
		if( upgrade_possible_to ) then
			formspec = formspec.."label[1.0,4.5;Possible future upgrade:]";
		end
		-- store the current status
		stored_building.complete = 0;
		citybuilder.save_data();
		return formspec..
			"label[1.0,3.0;Status: Number of blocks that need to be..]"..
			"label[1.5,3.5;..digged: "..stored_building.nodes_to_dig.."]"..
			"label[1.5,4.0;..placed: "..stored_building.nodes_to_place.."]"..
			"button_exit[6.0,1.5;3,0.5;update;Update status]"..
			"button_exit[6.0,2.3;3.0,0.5;preview;Preview]"..
			"button_exit[6.0,3.35;3.0,0.5;remove_indicators;Remove scaffolding]"..
			"button_exit[6.0,4.15;3.0,0.5;show_needed;Show materials needed]";
	end


	-- set the level of the (completed) building
	meta:set_int( "citybuilder_level", building_data.level+1 );
	meta:set_int( "complete", 1 );

	if( upgrade_possible_to ) then

		-- only the owner/founder can do upgrades
		if( not( citybuilder.can_access_inventory( pos, player))) then
			stored_building.complete = 0;
			return formspec..
				"label[0,0.1;Only the founder of this city may upgrade buildings.]";
		end

		local upgrade_data = build_chest.building[ citybuilder.mts_path..upgrade_possible_to ];
		-- TODO: check if upgrade is allowed
		local descr = upgrade_possible_to;
		if( upgrade_possible_to and upgrade_data and upgrade_data.descr ) then
			descr = upgrade_data.descr;
		end

		if( not( do_upgrade )) then
			stored_building.complete = 0;
			return formspec..
				"label[1.0,3.0;Status:]"..
				"label[1.5,3.5;Complete]"..
				"label[1.0,4.5;Upgrade to level "..tostring( upgrade_data.level ).." available:]"..
				"button_exit[6.0,4.5;3.0,0.5;upgrade;Upgrade now]";
		end

		meta:set_string( 'building_name', citybuilder.mts_path..upgrade_possible_to );
		-- store it in the city data structure
		stored_building.building_name = upgrade_possible_to;
		stored_building.level =  building_data.level+1;
		stored_building.complete = 1;
		citybuilder.save_data();
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

	-- remove "dig here" indicators and configured scaffolding nodes
	if( fields.remove_indicators ) then
		handle_schematics.abort_project_remove_indicators( meta );
		return;
	end

	-- most functions are accessible to all players; only upgrades are limited to the owner
	local formspec = "";

	-- show preview (2d image) of how the finished building will look like
	if( fields.preview and not( fields.end_preview )) then
		if( fields.preview == "Preview" ) then
			fields.preview = "front";
		end
		-- TODO: get this from the data structure
		local building_name = meta:get_string( 'building_name' );
		local replacements = citybuilder.get_wood_replacements( meta:get_string( "wood"), {} );
		formspec = "size[10,10]"..
			"label[3,1;Preview]"..
			"button[7,1;2.5,0.5;end_preview;Back to main menu]"..
			"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]"..
			build_chest.preview_image_formspec( building_name, replacements, fields.preview);

	-- list which materials are needed
	elseif( fields.show_needed ) then
		formspec = "size[9,7]"..
			"label[0,1.5;Materials needed to complete this project (click on \"Update status\" to update):]"..
			"list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";needed;0,2;8,5;]"..
			"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]"..
			"button_exit[0.5,0.7;2,0.5;update;Update status]"..
			"button[7.5,0.7;1,0.5;back;Back]";
	else
		formspec = citybuilder.constructor_update( pos, player, meta, fields.upgrade, not(fields.update) );
	end
	minetest.show_formspec( player:get_player_name(), "citybuilder:constructor", formspec );
end


minetest.register_node("citybuilder:constructor", {
	description = "constructor for a house",
	tiles = {"default_chest_side.png", "default_chest_top.png", "default_chest_side.png", -- TODO: a universal texture would be better
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png^beds_bed.png"},

	drawtype = "nodebox",
        node_box = {
                type = "fixed",
                fixed = {
                        {-0.5, -0.5+3/16, 0.5-3/16, 0.5, 0.5, 0.5-1/16},
                        {-0.5+1/16, -0.5,      0.5-1/16, -0.5+3/16, 0.5, 0.5     },
                        { 0.5-3/16, -0.5,      0.5-1/16,  0.5-1/16, 0.5, 0.5     },
                },
        },

	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2,not_in_creative_inventory=1},
	legacy_facedir_simple = true,
	-- constructors are configured; stacking would not be a good idea
	stack_max = 1,
	-- when digging, return unconfigured constructor; but: in after_dig_node it is exchanged for a configured one
	drop = "citybuilder:constructor_blank",

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

	on_place = function(itemstack, placer, pointed_thing)
		return citybuilder.constructor_on_place( itemstack, placer, pointed_thing, "above" );
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
			minetest.chat_send_player(name, "This building constructor belongs to "..tostring( owner_name )..". You can't take it.");
			return false;
		end

		local level = meta:get_int( "citybuilder_level" );
		if( level and level > 0 ) then
			minetest.chat_send_player(name, "This building constructor has spawned a building and cannot be digged.");
			return false;
		end
		-- TODO: only allow aborting a project if level 0 has not been completed yet
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
	end,
})


-- helper item; blank constructors cannot be placed
minetest.register_craftitem("citybuilder:constructor_blank", {
	description = "Blank constructor",
	inventory_image = "default_paper.png^[transformFX",
        groups = {},
})

minetest.register_craft({
	output = "citybuilder:constructor_blank",
	recipe = {
		{"default:paper", "default:paper", "default:paper"},
		{"default:paper", "default:paper", "default:paper"},
		{"", "default:chest", "default:sign_wall"}
	}
})
