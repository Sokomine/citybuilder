


citybuilder.show_error_msg = function( player, error_msg )
	if( player and player:is_player()) then
		minetest.chat_send_player( player:get_player_name(), error_msg );
	end
end



-- a player clicked on something in a formspec he was shown
citybuilder.form_input_handler = function( player, formname, fields)
	if(formname == "citybuilder:constructor" and fields and fields.pos2str) then
		local pos = minetest.string_to_pos( fields.pos2str );
		citybuilder.constructor_on_receive_fields(pos, formname, fields, player);
	end
end

-- make sure we receive player input; needed for showing formspecs directly (which is in turn faster than just updating the node)
minetest.register_on_player_receive_fields( citybuilder.form_input_handler );
