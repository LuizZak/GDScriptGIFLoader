## The Logical Screen Descriptor component of a Graphics Interchange Format
## stream.
## See http://www.w3.org/Graphics/GIF/spec-gif89a.txt section 18.
##
## The Logical Screen Descriptor contains the parameters necessary to
## define the area of the display device within which the images will be
## rendered. The coordinates in this block are given with respect to the
## top-left corner of the virtual screen; they do not necessarily refer to
## absolute coordinates on the display device.  This implies that they
## could refer to window coordinates in a window-based environment or
## printer coordinates when a printer is used.
## This block is REQUIRED; exactly one Logical Screen Descriptor must be
## present per Data Stream.
class_name LogicalScreenDescriptor

var _screen_size: Vector2i
var _has_global_color_table: bool
var _color_resolution: int
var _gct_is_sorted: bool
var _gct_size_bits: int
var _background_color_index: int
var _pixel_aspect_ratio: int
var _error: Error

func _init(input_stream: ByteReaderStream) -> void:
    if input_stream.remaining_bytes < 7:
        _error = Error.ERR_FILE_CORRUPT
        return

    var width := input_stream.read_short()
    var height := input_stream.read_short()
    _screen_size = Vector2i(width, height)

    var packed := PackedField.new(input_stream.read_byte())
    _has_global_color_table = packed.get_bit(0)
    _color_resolution = packed.get_bits(1, 3)
    _gct_is_sorted = packed.get_bit(4)
    _gct_size_bits = packed.get_bits(5, 3)

    _background_color_index = input_stream.read_byte()
    _pixel_aspect_ratio = input_stream.read_byte()

## Gets any error found during initialization.
## If no errors were found, returns `Error.OK`.
func get_error() -> Error:
    return _error

## Gets the width and height, in pixels, of the logical screen where
## the images will be rendered in the displaying device.
func screen_size() -> Vector2i:
    return _screen_size

## Gets a flag indicating the presence of a Global Color Table; if the
## flag is set, the Global Color Table will immediately follow the
## Logical Screen Descriptor. This flag also selects the interpretation
## of the Background Color Index; if the flag is set, the value of the
## Background Color Index field should be used as the table index of
## the background color.
func has_global_color_table() -> bool:
    return _has_global_color_table

## Gets the number of bits per primary color available to the original
## image, minus 1. This value represents the size of the entire palette
## from which the colors in the graphic were selected, not the number
## of colors actually used in the graphic.
## For example, if the value in this field is 3, then the palette of
## the original image had 4 bits per primary color available to create
## the image.  This value should be set to indicate the richness of
## the original palette, even if not every color from the whole
## palette is available on the source machine.
func color_resolution() -> int:
    return _color_resolution

## Indicates whether the Global Color Table is sorted.
## If the flag is set, the Global Color Table is sorted, in order of
## decreasing importance. Typically, the order would be decreasing
## frequency, with most frequent color first. This assists a decoder,
## with fewer available colors, in choosing the best subset of colors;
## the decoder may use an initial segment of the table to render the
## graphic.
func gct_is_sorted() -> bool:
    return _gct_is_sorted

## If the Global Color Table Flag is set to 1, the value in this field
## is used to calculate the number of bytes contained in the Global
## Color Table. To determine that actual size of the color table,
## raise 2 to [the value of the field + 1].
## Even if there is no Global Color Table specified, set this field
## according to the above formula so that decoders can choose the best
## graphics mode to display the stream in.
func gct_size_bits() -> int:
    return _gct_size_bits

## Gets the number of colors in the global color table.
func global_color_table_size() -> int:
    return 2 << _gct_size_bits

## Gets the index into the Global Color Table for the Background Color.
## The Background Color is the color used for those pixels on the
## screen that are not covered by an image.
## If the Global Color Table Flag is set to (zero), this field should
## be zero and should be ignored.
func background_color_index() -> int:
    return _background_color_index

## Gets the factor used to compute an approximation of the aspect ratio
## of the pixel in the original image.  If the value of the field is
## not 0, this approximation of the aspect ratio is computed based on
## the formula:
##
## Aspect Ratio = (Pixel Aspect Ratio + 15) / 64
##
## The Pixel Aspect Ratio is defined to be the quotient of the pixel's
## width over its height.  The value range in this field allows
## specification of the widest pixel of 4:1 to the tallest pixel of
## 1:4 in increments of 1/64th.
func pixel_aspect_ratio() -> int:
    return _pixel_aspect_ratio
