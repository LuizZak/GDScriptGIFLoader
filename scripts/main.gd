class_name Main
extends Control

@onready
var file_dialog: FileDialog = %FileDialog
@onready
var animated_sprite: AnimatedSprite2D = %AnimatedSprite

func _ready() -> void:
    file_dialog.filters = ["*.gif;GIF Files;image/gif"]
    file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE

func _on_load_gif_button_pressed() -> void:
    file_dialog.show()

func _on_file_dialog_file_selected(path: String) -> void:
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return

    var start_time = Time.get_ticks_msec()

    var buffer = file.get_buffer(file.get_length())
    var gif_decoder = GifDecoder.new(buffer)

    animated_sprite.sprite_frames = gif_decoder.get_sprite_frames()
    animated_sprite.play(&"default")

    var end_time = Time.get_ticks_msec()

    print("%.2fs" % ((end_time - start_time) / 1000.0))
