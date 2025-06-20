## Describes a single image within a Graphics Interchange Format data
## stream.
## See http://www.w3.org/Graphics/GIF/spec-gif89a.txt section 20.
##
## Each image in the Data Stream is composed of an Image Descriptor, an
## optional Local Color Table, and the image data.  Each image must fit
## within the boundaries of the Logical Screen, as defined in the
## Logical Screen Descriptor.
##
## The Image Descriptor contains the parameters necessary to process a
## table based image. The coordinates given in this block refer to
## coordinates within the Logical Screen, and are given in pixels. This
## block is a Graphic-Rendering Block, optionally preceded by one or more
## Control blocks such as the Graphic Control Extension, and may be
## optionally followed by a Local Color Table; the Image Descriptor is
## always followed by the image data.
##
## This block is REQUIRED for an image.  Exactly one Image Descriptor must
## be present per image in the Data Stream.  An unlimited number of images
## may be present per Data Stream.
##
## The scope of this block is the Table-based Image Data Block that
## follows it. This block may be modified by the Graphic Control Extension.
class_name ImageDescriptor

var _position: Vector2i
var _size: Vector2i
var _has_local_color_table: bool
var _is_interlaced: bool
var _is_sorted: bool
var _local_color_table_size_bits: int
var _error: Error

func _init(input_stream: ByteReaderStream) -> void:
    if input_stream.remaining_bytes < 17:
        _error = Error.ERR_FILE_CORRUPT
        return

    var left_position := input_stream.read_short() # (sub)image position & size
    var top_position := input_stream.read_short()
    var width := input_stream.read_short()
    var height := input_stream.read_short()

    _position = Vector2i(left_position, top_position)
    _size = Vector2i(width, height)

    var packed := PackedField.new(input_stream.read_byte())
    _has_local_color_table = packed.get_bit(0)
    _is_interlaced = packed.get_bit(1)
    _is_sorted = packed.get_bit(2)
    _local_color_table_size_bits = packed.get_bits(5, 3)

## Gets any error found during initialization.
## If no errors were found, returns `Error.OK`.
func get_error() -> Error:
    return _error

## Gets the position, in pixels, of the top-left corner of the image,
## with respect to the top-left corner of the logical screen.
## Top-left corner of the logical screen is 0,0.
func position() -> Vector2i:
    return _position

## Gets the size of the image in pixels.
func size() -> Vector2i:
    return _size

## Gets a boolean value indicating the presence of a Local Color table immediately
## following this Image Descriptor.
func has_local_color_table() -> bool:
    return _has_local_color_table

## Gets a boolean value indicating whether the image is interlaced. An
## image is interlaced in a four-pass interlace pattern; see Appendix E
## for details.
func is_interlaced() -> bool:
    return _is_interlaced

## Gets a boolean value indicating whether the Local Color Table is
## sorted.  If the flag is set, the Local Color Table is sorted, in
## order of decreasing importance. Typically, the order would be
## decreasing frequency, with most frequent color first. This assists
## a decoder, with fewer available colors, in choosing the best subset
## of colors; the decoder may use an initial segment of the table to
## render the graphic.
func is_sorted() -> bool:
    return _is_sorted

## If the Local Color Table Flag is set to 1, the value in this field
## is used to calculate the number of bytes contained in the Local
## Color Table. To determine that actual size of the color table,
## raise 2 to the value of the field + 1.
## This value should be 0 if there is no Local Color Table specified.
func local_color_table_size_bits() -> int:
    return _local_color_table_size_bits

## Gets the actual size of the local colour table.
func local_color_table_size() -> int:
    return 2 << _local_color_table_size_bits
