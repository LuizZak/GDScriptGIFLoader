class_name Main
extends Control

@onready
var time_to_load_label: Label = %TimeToLoadLabel
@onready
var animated_sprite: AnimatedSprite2D = %AnimatedSprite
@onready
var file_path_label: Label = %FilePathLabel
@onready
var loading_panel_container: PanelContainer = %LoadingPanelContainer
@onready
var file_dialog: FileDialog = %FileDialog

var _latest_thread: Thread = null

func _ready() -> void:
    file_dialog.access = FileDialog.ACCESS_FILESYSTEM
    file_dialog.current_dir = OS.get_executable_path().get_base_dir()
    file_dialog.use_native_dialog = true
    file_dialog.filters = ["*.gif;GIF Files;image/gif"]
    file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE

func _process(delta: float) -> void:
    if _latest_thread != null:
        if not _latest_thread.is_alive():
            var result: GifLoadResult = _latest_thread.wait_to_finish()
            _update(result)
            _latest_thread = null
            loading_panel_container.visible = false

func _on_load_gif_button_pressed() -> void:
    file_dialog.show()

func _on_file_dialog_file_selected(path: String) -> void:
    file_path_label.text = path

    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return

    loading_panel_container.visible = true

    _latest_thread = Thread.new()
    var buffer := file.get_buffer(file.get_length())
    _latest_thread.start(_load_gif.bind(buffer), Thread.PRIORITY_HIGH)

func _update(result: GifLoadResult) -> void:
    animated_sprite.sprite_frames = result.sprite_frames
    animated_sprite.play(&"default")

    var elapsed := result.total_time
    time_to_load_label.text = "%.2fs" % (elapsed / 1000.0)

func _load_gif(buffer: PackedByteArray) -> GifLoadResult:
    var start_time := Time.get_ticks_msec()

    var gif_decoder := GifDecoder.new(buffer)
    var sprite_frames := gif_decoder.get_sprite_frames()

    var end_time := Time.get_ticks_msec()

    return GifLoadResult.new(
        sprite_frames,
        end_time - start_time
    )

class GifLoadResult:
    var sprite_frames: SpriteFrames
    var total_time: float

    func _init(sprite_frames: SpriteFrames, total_time: float) -> void:
        self.sprite_frames = sprite_frames
        self.total_time = total_time
