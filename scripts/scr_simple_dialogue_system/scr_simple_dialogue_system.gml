function SimpleDialogueSystem(_voice = snd_voice2, _voice_min = 1, _voice_max = 2, _dialogue_complete = undefined, _character_sprite = undefined, _dialogue_background = spr_dialogue_background) constructor {
	current_dialogue		= -1;
	current_dialogue_index	= -1;
	available_dialogues		= [];
	dialogue_complete		= _dialogue_complete;
	voice					= _voice;
	voice_min				= _voice_min;
	voice_max				= _voice_max;
	
	waiting_on_input		= false;
	typist					= scribble_typist();
	waiting_on_typist		= false;
	
	skip_pressed			= false;
	
	typist.in(0.4, 1);
	typist.function_on_complete(function() {
		waiting_on_typist	= false;	
		skip_pressed		= false;
	});
	typist.sound_per_char(voice, voice_min, voice_max);
	
	character_sprite		= _character_sprite;
	dialogue_background		= _dialogue_background;
	
	
	static load_dialogue = function(_name) {
			for (var _i = 0; _i < array_length(available_dialogues); _i++) {
				if (available_dialogues[_i].name == _name) {
					current_dialogue = available_dialogues[_i];	
					advance_dialogue();
				}
			}
	}
	
	static load_from_file = function(_file_path) {
		if (!file_exists(_file_path)) {
			show_debug_message("Unable to locate file.");
			return;
		}
		
		var _file			= file_text_open_read(_file_path);
		var _json_string	= "";
		
		while (!file_text_eof(_file)) {
			_json_string += file_text_readln(_file);	
		}
		file_text_close(_file);
		
		var _json_data = json_parse(_json_string);
		
		for (var _i = 0; _i < array_length(_json_data); _i++) {
			var _dialogue			= _json_data[_i];
			var _dialogue_entries	= [];

			for (var _j = 0; _j < array_length(_dialogue.entries); _j++) {
				var _entry		= _dialogue.entries[_j];
				var _choices	= undefined;
				var _l_callback = undefined;
				
				if (struct_exists(_entry, "callback")) {
					_l_callback = _entry.callback;	
				}

				if (variable_struct_exists(_entry, "choices")) {
					_choices = [];
					for (var _k = 0; _k < array_length(_entry.choices); _k++) {
						var _choice		= _entry.choices[_k];
						var _callback	= undefined;
						
						if (variable_struct_exists(_choice, "callback")) {
							_callback = _choice.callback;
						}
						
						array_push(_choices, new SimpleDialogueChoice(
							_choice.text,
							_choice.jump,
							_callback
						));
					}
				}
				
				_jump = undefined;
				if (variable_struct_exists(_entry, "jump")) {
					_jump = _entry.jump;
				}
				
				array_push(_dialogue_entries, new SimpleDialogueEntry(
					_entry.name,
					_entry.speaker,
					_entry.text,
					_jump,
					_l_callback,
					_choices
				));
			}
			
			add_dialogue(_dialogue.name, _dialogue_entries);
		}
	}
	
	static advance_dialogue = function() {
		if (waiting_on_input) return;
		
		if (current_dialogue_index + 1 < array_length(current_dialogue.dialogue_messages)) {
			current_dialogue_index++;	
			if (current_dialogue.dialogue_messages[current_dialogue_index].choices != undefined) {
				waiting_on_input = true;	
			}
		} else {
			if (is_method(dialogue_complete)) {
				dialogue_complete();	
			}
		}
		waiting_on_typist	= true;
		skip_pressed		= false;
	}
	
	static add_dialogue = function(_name, _dialogue_messages = []) {
			array_push(available_dialogues, {
				name:				_name,
				dialogue_messages:	_dialogue_messages,
			});
	}
	
	static jump = function(_entry) {
		if (current_dialogue != -1) {
			for (var _i = 0; _i < array_length(current_dialogue.dialogue_messages); _i++) {
				if (current_dialogue.dialogue_messages[_i].name == _entry) {
					current_dialogue_index	= _i;
					waiting_on_input		= false;
					waiting_on_typist		= true;
					skip_pressed			= false;
					
					if (current_dialogue.dialogue_messages[_i].choices != undefined) {
						waiting_on_input	= true;
						skip_pressed		= true;
					} else {
						waiting_on_input	= false;
						skip_pressed		= false;
					}
					return;
				}
			}
		}
	}
	
	static update = function() {
		var _root = current_dialogue.dialogue_messages[current_dialogue_index];
		
		if (current_dialogue != -1) {
			if (input_check_pressed("action")) {
				if (skip_pressed) return;
				
				if (waiting_on_typist) {
					typist.skip();
					skip_pressed = true;	
					return;
				}
				
				if (variable_struct_exists(_root, "callback")) {
				    var _callback_string = _root.callback;
				    if (_callback_string != undefined && _callback_string != "") {
				        try {
				            var _cb = Catspeak.parseString(_callback_string);
				            var _md = Catspeak.compile(_cb);
				            _md();
				        } catch(_e) {
				            show_debug_message("Error executing callback: " + string(_e));
				        }
				    }
				}

				if (_root.jump != undefined) {
					jump(_root.jump);
					return;
				}
				advance_dialogue();
			}
			if (waiting_on_input) {	
				if (input_check_pressed("up")) {
					if (_root.selected_index - 1 > -1) {
						_root.selected_index--;	
					} else {
						_root.selected_index = array_length(_root.choices) - 1;	
					}
				} else if (input_check_pressed("down")) {
					if (_root.selected_index + 1 < array_length(_root.choices)) {
						_root.selected_index++;	
					} else {
						_root.selected_index = 0;	
					}
				} else if (input_check_pressed("action")) {
					if (skip_pressed) return;
				
					if (waiting_on_typist) {
						typist.skip();
						skip_pressed = true;
						return;
					}
					
					if (variable_struct_exists(_root.choices[_root.selected_index], "callback")) {
						var _callback_string = _root.choices[_root.selected_index].callback;
						if (_callback_string != undefined && _callback_string != "") {
							try {
								var _cb = Catspeak.parseString(_root.choices[_root.selected_index].callback);
								var _md = Catspeak.compile(_cb);
								_md();
							} catch(_e) {
								show_message(_e);	
							}
						}
					}
					if (_root.choices[_root.selected_index].jump != undefined) {
						jump(_root.choices[_root.selected_index].jump);
						return;
					}
					
					if (variable_struct_exists(_root, "callback")) {
						var _callback_string = _root.callback;
						if (_callback_string != undefined && _callback_string != "") {
							try {
								var _cb = Catspeak.parseString(_root.callback);
								var _md = Catspeak.compile(_cb);
								_md();
							} catch(_e) {
								show_message(_e);	
							}
						}
					
					waiting_on_input = false;
					advance_dialogue();
				}
			}
			}
		}
	}
	
	static draw = function() {
		if (current_dialogue != -1) {
			var _root = current_dialogue.dialogue_messages[current_dialogue_index];
			
			// Draw the background
			var _start_x = display_get_gui_width() / 2 - 208;
			var _max_width = 400;
			
			if (character_sprite != undefined) {
				_start_x += 74;	
				_max_width = 400 - 74;
			}
			
			if (character_sprite != undefined) {
				draw_sprite_stretched(dialogue_background, 0, _start_x - 74, display_get_gui_height() - 104, 72, 72);
				draw_sprite_stretched(dialogue_background, 0, _start_x, display_get_gui_height() - 104, 416 - 74, 72);
				draw_sprite(character_sprite, 0, _start_x - 74 + 37, display_get_gui_height() - 104 + 37);
			} else {
				draw_sprite_stretched(dialogue_background, 0, display_get_gui_width() / 2 - 208, display_get_gui_height() - 104, 416, 72);
			}
			
			// Draw the text
			scribble("[c_dark]" + _root.text).wrap(300).fit_to_box(_max_width, 68).draw(_start_x + 4, display_get_gui_height() - 100, typist);
			
			// Draw the speakers name
			draw_sprite_stretched(spr_dialogue_background, 0, display_get_gui_width() / 2 - 208, display_get_gui_height() - 126, 100, 20);
			scribble("[c_d_blue]" + _root.speaker).draw(display_get_gui_width() / 2 - 204, display_get_gui_height() - 120);
			
			__scribble_config_colours()
			
			if (waiting_on_typist) return;
			if (_root.choices != undefined) {
				for (var _i = 0; _i < array_length(_root.choices); _i++) {
					if (_i == _root.selected_index) {
						draw_sprite_stretched(dialogue_background, 0, display_get_gui_width() / 2 + 208 - string_width(_root.choices[_i].text), display_get_gui_height() - 126, string_width(_root.choices[_i].text), 20);
						scribble("[c_d_green]" + _root.choices[_i].text).draw(display_get_gui_width() / 2 + 212 - string_width(_root.choices[_i].text), display_get_gui_height() - 120);
					}
				}
			} else {
				draw_sprite(spr_dialogue_pointer, 0, display_get_gui_width() / 2 + 208 - 24, display_get_gui_height() - 52);
			}
		}
	}
}
