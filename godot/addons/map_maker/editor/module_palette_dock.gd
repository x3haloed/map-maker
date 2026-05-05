@tool
class_name ModulePaletteDock
extends VBoxContainer

signal validate_requested
signal create_requested(module_path: String)
signal attach_requested(module_path: String, new_socket_name: StringName, target_socket_name: StringName)
signal authoring_state_changed

var _module_paths: Array[String] = []
var _selected_instance: ModuleInstance3D
var _compatibility: SocketCompatibility
var _module_picker: OptionButton
var _target_socket_picker: OptionButton
var _new_socket_picker: OptionButton
var _attach_button: Button
var _create_button: Button
var _selection_label: Label
var _socket_pick_label: Label
var _compatibility_label: Label
var _results: RichTextLabel


func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = "Map Maker"
	add_child(title)

	_selection_label = Label.new()
	_selection_label.text = "No ModuleInstance3D selected."
	_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_selection_label)

	_socket_pick_label = Label.new()
	_socket_pick_label.text = "Click a socket marker in the viewport to pick it."
	_socket_pick_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_socket_pick_label)

	var module_label := Label.new()
	module_label.text = "Module"
	add_child(module_label)

	_module_picker = OptionButton.new()
	_module_picker.item_selected.connect(func(_index: int): _refresh_new_socket_picker(); authoring_state_changed.emit())
	add_child(_module_picker)

	_create_button = Button.new()
	_create_button.text = "Create Module"
	_create_button.pressed.connect(_emit_create)
	add_child(_create_button)

	var target_socket_label := Label.new()
	target_socket_label.text = "Selected Socket"
	add_child(target_socket_label)

	_target_socket_picker = OptionButton.new()
	_target_socket_picker.item_selected.connect(func(_index: int): _select_first_compatible_new_socket(); _update_attach_state(); authoring_state_changed.emit())
	add_child(_target_socket_picker)

	var new_socket_label := Label.new()
	new_socket_label.text = "New Module Socket"
	add_child(new_socket_label)

	_new_socket_picker = OptionButton.new()
	_new_socket_picker.item_selected.connect(func(_index: int): _update_attach_state(); authoring_state_changed.emit())
	add_child(_new_socket_picker)

	_attach_button = Button.new()
	_attach_button.text = "Attach Module"
	_attach_button.pressed.connect(_emit_attach)
	add_child(_attach_button)

	_compatibility_label = Label.new()
	_compatibility_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_compatibility_label)

	var validate_button := Button.new()
	validate_button.text = "Validate Map"
	validate_button.pressed.connect(func(): validate_requested.emit())
	add_child(validate_button)

	_results = RichTextLabel.new()
	_results.fit_content = true
	_results.scroll_active = true
	_results.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_results)

	load_module_directory("res://addons/map_maker/examples/modules")
	set_selected_instance(null)
	set_validation_results([], 0)


func load_module_directory(directory_path: String) -> void:
	_module_paths.clear()
	_module_picker.clear()

	var directory := DirAccess.open(directory_path)
	if directory == null:
		return

	directory.list_dir_begin()
	var file_name := directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and file_name.ends_with(".tres"):
			var module_path := "%s/%s" % [directory_path, file_name]
			var definition: ModuleDefinition = load(module_path)
			if definition != null:
				_module_paths.append(module_path)
				_module_picker.add_item(definition.display_name)
		file_name = directory.get_next()
	directory.list_dir_end()

	_refresh_new_socket_picker()


func set_selected_instance(instance: ModuleInstance3D) -> void:
	_selected_instance = instance
	_target_socket_picker.clear()

	if _selected_instance == null:
		_selection_label.text = "No ModuleInstance3D selected."
		_socket_pick_label.text = "Click a socket marker in the viewport to pick it."
		_update_attach_state()
		return

	_selection_label.text = "Selected: %s" % _selected_instance.name
	if _selected_instance.module_definition != null:
		for socket in _selected_instance.module_definition.sockets:
			_target_socket_picker.add_item(_socket_label(socket))

	_update_attach_state()


func set_socket_compatibility(compatibility: SocketCompatibility) -> void:
	_compatibility = compatibility
	_update_attach_state()


func pick_target_socket(socket_name: StringName) -> void:
	if _selected_instance == null or _selected_instance.module_definition == null:
		return

	for index in range(_selected_instance.module_definition.sockets.size()):
		if _selected_instance.module_definition.sockets[index].socket_name == socket_name:
			_target_socket_picker.select(index)
			_socket_pick_label.text = "Picked socket: %s" % socket_name
			_update_attach_state()
			authoring_state_changed.emit()
			return


func compatible_new_socket_names() -> Array[StringName]:
	var names: Array[StringName] = []
	var target_socket := selected_target_socket()
	var new_definition: ModuleDefinition = load(selected_module_path())
	if target_socket == null or new_definition == null or _compatibility == null:
		return names

	for socket in new_definition.sockets:
		if _compatibility.allows(socket.socket_type, target_socket.socket_type):
			names.append(socket.socket_name)

	return names


func set_validation_results(issues: Array[ValidationIssue], instance_count: int) -> void:
	_results.clear()
	if issues.is_empty():
		_results.append_text("Validation passed for %d module instance(s)." % instance_count)
		return

	for issue in issues:
		var severity := "Warning" if issue.severity == ValidationIssue.Severity.WARNING else "Error"
		_results.append_text("%s [%s]\n%s\n\n" % [severity, issue.code, issue.message])


func selected_module_path() -> String:
	var index := _module_picker.selected
	if index < 0 or index >= _module_paths.size():
		return ""
	return _module_paths[index]


func selected_target_socket_name() -> StringName:
	if _selected_instance == null or _selected_instance.module_definition == null:
		return &""

	var index := _target_socket_picker.selected
	if index < 0 or index >= _selected_instance.module_definition.sockets.size():
		return &""
	return _selected_instance.module_definition.sockets[index].socket_name


func selected_target_socket() -> ModuleSocket:
	if _selected_instance == null or _selected_instance.module_definition == null:
		return null

	var index := _target_socket_picker.selected
	if index < 0 or index >= _selected_instance.module_definition.sockets.size():
		return null
	return _selected_instance.module_definition.sockets[index]


func selected_new_socket_name() -> StringName:
	var definition: ModuleDefinition = load(selected_module_path())
	if definition == null:
		return &""

	var index := _new_socket_picker.selected
	if index < 0 or index >= definition.sockets.size():
		return &""
	return definition.sockets[index].socket_name


func selected_new_socket() -> ModuleSocket:
	var definition: ModuleDefinition = load(selected_module_path())
	if definition == null:
		return null

	var index := _new_socket_picker.selected
	if index < 0 or index >= definition.sockets.size():
		return null
	return definition.sockets[index]


func _refresh_new_socket_picker() -> void:
	if _new_socket_picker == null:
		return

	_new_socket_picker.clear()
	var definition: ModuleDefinition = load(selected_module_path())
	if definition == null:
		_attach_button.disabled = true
		_create_button.disabled = true
		return

	for socket in definition.sockets:
		_new_socket_picker.add_item(_socket_label(socket))

	_create_button.disabled = false
	_select_first_compatible_new_socket()
	_update_attach_state()


func _emit_create() -> void:
	var module_path := selected_module_path()
	if module_path != "":
		create_requested.emit(module_path)


func _emit_attach() -> void:
	var module_path := selected_module_path()
	var target_socket_name := selected_target_socket_name()
	var new_socket_name := selected_new_socket_name()
	if module_path != "" and target_socket_name != &"" and new_socket_name != &"":
		attach_requested.emit(module_path, new_socket_name, target_socket_name)


func _select_first_compatible_new_socket() -> void:
	var target_socket := selected_target_socket()
	var new_definition: ModuleDefinition = load(selected_module_path())
	if target_socket == null or new_definition == null or _compatibility == null:
		return

	for index in range(new_definition.sockets.size()):
		if _compatibility.allows(new_definition.sockets[index].socket_type, target_socket.socket_type):
			_new_socket_picker.select(index)
			return


func _update_attach_state() -> void:
	if _attach_button == null or _compatibility_label == null:
		return

	var target_socket := selected_target_socket()
	var new_socket := selected_new_socket()
	var can_attach := target_socket != null and new_socket != null and _compatibility != null and _compatibility.allows(new_socket.socket_type, target_socket.socket_type)

	_attach_button.disabled = not can_attach
	if target_socket == null:
		_compatibility_label.text = "Select or click a target socket."
	elif new_socket == null:
		_compatibility_label.text = "Choose a module socket to attach."
	elif can_attach:
		_compatibility_label.text = "%s can connect to %s." % [new_socket.socket_type, target_socket.socket_type]
	else:
		_compatibility_label.text = "%s cannot connect to %s." % [new_socket.socket_type, target_socket.socket_type]


func _socket_label(socket: ModuleSocket) -> String:
	return "%s  (%s)" % [socket.socket_name, socket.socket_type]
