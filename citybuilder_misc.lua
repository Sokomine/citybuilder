

-- only the owner can use the inventory
citybuilder.can_access_inventory = function( pos, player )
	if( not( pos ) or not( player )) then
		return false;
	end
	local meta = minetest.get_meta( pos );
	local owner = meta:get_string( "owner" );
	if( owner == player:get_player_name()) then
		return true;
	else
		return false;
	end
end


citybuilder.show_error_msg = function( player, error_msg )
	if( player and player:is_player()) then
		minetest.chat_send_player( player:get_player_name(), error_msg );
	end
end



-- a player clicked on something in a formspec he was shown
citybuilder.form_input_handler = function( player, formname, fields)

	-- menu of constructorrs for building individual houses
	if(formname == "citybuilder:constructor" and fields and fields.pos2str) then
		local pos = minetest.string_to_pos( fields.pos2str );
		citybuilder.constructor_on_receive_fields(pos, formname, fields, player);
	end
	-- menu of city administration device
	if(formname == "citybuilder:cityadmin"   and fields and fields.pos2str) then
		local pos = minetest.string_to_pos( fields.pos2str );
		citybuilder.cityadmin_on_receive_fields(  pos, formname, fields, player);
	end
end

-- make sure we receive player input; needed for showing formspecs directly (which is in turn faster than just updating the node)
minetest.register_on_player_receive_fields( citybuilder.form_input_handler );
