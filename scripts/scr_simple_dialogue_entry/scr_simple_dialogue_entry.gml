function SimpleDialogueEntry(_name, _speaker, _text, _jump = undefined, _callback = undefined, _choices = undefined) constructor {
	name			= _name;
	speaker			= _speaker;
	text			= _text;
	choices			= _choices;
	callback		= _callback;
	selected_index	= 0;
	jump			= _jump;
}
