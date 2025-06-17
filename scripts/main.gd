class_name Main
extends Control

@onready
var time_to_load_label: Label = %TimeToLoadLabel
@onready
var animated_sprite: AnimatedSprite2D = %AnimatedSprite
@onready
var file_path_label: Label = %FilePathLabel
@onready
var file_dialog: FileDialog = %FileDialog

func _ready() -> void:
    file_dialog.access = FileDialog.ACCESS_FILESYSTEM
    file_dialog.current_dir = OS.get_executable_path().get_base_dir()
    file_dialog.use_native_dialog = true
    file_dialog.filters = ["*.gif;GIF Files;image/gif"]
    file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE

func _on_load_gif_button_pressed() -> void:
    file_dialog.show()

func _on_file_dialog_file_selected(path: String) -> void:
    file_path_label.text = path

    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return

    var start_time = Time.get_ticks_msec()

    var buffer = file.get_buffer(file.get_length())
    var gif_decoder = GifDecoder.new(buffer)

    animated_sprite.sprite_frames = gif_decoder.get_sprite_frames()
    animated_sprite.play(&"default")

    var end_time = Time.get_ticks_msec()

    time_to_load_label.text = "%.2fs" % ((end_time - start_time) / 1000.0)
