## A global or local color table which forms part of a GIF data stream.
class_name ColorTable

## The colors in the color table in 32-bit integer form.
var _int_colors: PackedInt32Array
var _error: Error

func _init(input_stream: ByteReaderStream, number_of_colors: int) -> void:
    if number_of_colors < 0 or number_of_colors > 256:
        _error = Error.ERR_FILE_CORRUPT
        return

    var bytes_expected := number_of_colors * 3

    if input_stream.remaining_bytes < bytes_expected:
        _error = Error.ERR_FILE_CORRUPT
        return

    var buffer := input_stream.read_data(bytes_expected)
    var colors_read := bytes_expected / 3

    _int_colors.resize(colors_read)

    var i := 0
    var j := 0
    while i < colors_read:
        var r := buffer.decode_u8(j) & 0xFF
        j += 1
        var g := buffer.decode_u8(j) & 0xFF
        j += 1
        var b := buffer.decode_u8(j) & 0xFF
        j += 1

        _int_colors[i] = (r << 24) | (g << 16) | (b << 8) | 255
        i += 1

## Gets any error found during initialization.
## If no errors were found, returns `Error.OK`.
func get_error() -> Error:
    return _error

## Gets the entire color table stored in this color table.
func get_color_table() -> PackedInt32Array:
    return _int_colors

## Gets the color at a specified index in this color table as a ARGB integer.
func get_color_int(index: int) -> int:
    return _int_colors[index]

## Gets the color at a specified index in this color table.
func get_color(index: int) -> Color:
    return Color.hex(get_color_int(index))

## Gets the length of this color table.
func get_length() -> int:
    return _int_colors.size()
