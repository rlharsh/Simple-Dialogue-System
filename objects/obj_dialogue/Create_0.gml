// Setup the GUI size
display_set_gui_size(480, 270);

// Setup the font
_font = font_add_sprite_ext(spr_carton, " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~", 1, 2);
scribble_font_set_default("spr_carton");

Catspeak.interface.exposeFunctionByName("show_message");
Catspeak.interface.exposeFunctionByName("game_end");

dialogue_system	= new SimpleDialogueSystem();
dialogue_system.load_from_file("dialogue/testing/test_script.json");
dialogue_system.load_dialogue("introduction");
