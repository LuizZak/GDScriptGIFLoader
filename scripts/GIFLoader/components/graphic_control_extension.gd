## The Graphic Control Extension contains parameters used when processing
## a graphic rendering block. The scope of this extension is the first
## graphic rendering block to follow. The extension contains only one
## data sub-block.
## This block is OPTIONAL; at most one Graphic Control Extension may
## precede a graphic rendering block. This is the only limit to the number
## of Graphic Control Extensions that may be contained in a Data Stream.
class_name GraphicControlExtension

## Enumeration of disposal methods that can be found in a Graphic Control
## Extension.
## See http://www.w3.org/Graphics/GIF/spec-gif89a.txt section 23.
enum DisposalMethod {
    NOT_SPECIFIED = 0,
    DO_NOT_DISPOSE = 1,
    RESTORE_TO_BACKGROUND_COLOR = 2,
    RESTORE_TO_PREVIOUS = 3,
}

var _block_size: int
var _disposal_method: DisposalMethod
var _expects_user_input: bool
var _has_transparent_color: bool
var _delay_time: int
var _transparent_color_index: int
var _error: Error

func _init(input_stream: ByteReaderStream):
    _block_size = input_stream.read_byte()

    var packed := PackedField.new(input_stream.read_byte())
    _disposal_method = packed.get_bits(3, 3) as DisposalMethod
    _expects_user_input = packed.get_bit(6)
    _has_transparent_color = packed.get_bit(7)

    if _disposal_method == 0:
        _disposal_method = DisposalMethod.DO_NOT_DISPOSE # Elect to keep old image if discretionary

    _delay_time = input_stream.read_short() # Delay in hundreths of a second
    _transparent_color_index = input_stream.read_byte() # Transparent color index
    input_stream.read_byte() # Block terminator

## Gets any error found during initialization.
## If no errors were found, returns `Error.OK`.
func get_error() -> Error:
    return _error

## Number of bytes in the block, after the Block Size field and up to
## but not including the Block Terminator.
## This field contains the fixed value 4.
func block_size() -> int:
    return _block_size

## Indicates the way in which the graphic is to be treated after being displayed.
func disposal_method() -> DisposalMethod:
    return _disposal_method

## <summary>
## Indicates whether or not user input is expected before continuing.
## If the flag is set, processing will continue when user input is
## entered.
## The nature of the User input is determined by the application
## (Carriage Return, Mouse Button Click, etc.).
##
## Values :    0 -   User input is not expected.
##             1 -   User input is expected.
##
## When a Delay Time is used and the User Input Flag is set,
## processing will continue when user input is received or when the
## delay time expires, whichever occurs first.
## </summary>
func expects_user_input() -> bool:
    return _expects_user_input

## Indicates whether a transparency index is given in the Transparent Index field.
func has_transparent_color() -> bool:
    return _has_transparent_color

## If not 0, this field specifies the number of hundredths (1/100)
## of a second to wait before continuing with the processing of the
## Data Stream.
## The clock starts ticking immediately after the graphic is rendered.
## This field may be used in conjunction with the User Input Flag field.
func delay_time() -> int:
    return _delay_time

## The Transparency Index is such that when encountered, the
## corresponding pixel of the display device is not modified and
## processing goes on to the next pixel.
## The index is present if and only if the Transparency Flag is set
## to 1.
func transparent_color_index() -> int:
    return _transparent_color_index
