## A data sub-block to form part of a Graphics Interchange Format data
## stream.
## See http://www.w3.org/Graphics/GIF/spec-gif89a.txt section 15.
##
## Data Sub-blocks are units containing data. They do not have a label,
## these blocks are processed in the context of control blocks, wherever
## data blocks are specified in the format. The first byte of the Data
## sub-block indicates the number of data bytes to follow. A data sub-block
## may contain from 0 to 255 data bytes. The size of the block does not
## account for the size byte itself, therefore, the empty sub-block is one
## whose size field contains 0x00.
class_name DataBlock

var _block_size: int
var _data: PackedByteArray
var _error: Error

func _init(input_stream: ByteReaderStream):
    if input_stream.is_eof():
        _error = Error.ERR_FILE_CORRUPT
        return

    _block_size = input_stream.read_byte()
    _data = input_stream.read_data(_block_size)

    if _data.size() != _block_size:
        _error = Error.ERR_FILE_CORRUPT
        return

## Gets any error found during initialization.
## If no errors were found, returns `Error.OK`.
func get_error() -> Error:
    return _error

## Gets the block size held in the first byte of this data block.
## This should be the same as the actual length of the data block but
## may not be if the data block was instantiated from a corrupt stream
## - check the get_error() method.
func get_declared_block_size() -> int:
    return _block_size

## Gets the actual length of the data.
func get_actual_block_size() -> int:
    return _data.size()

## Gets the data loaded into this data block.
## This does not include the first byte which holds the block size.
func get_data() -> PackedByteArray:
    return _data

## Gets the data loaded into this block, as a `ByteReaderStream`.
## This does not include the first byte which holds the block size.
func get_data_as_byte_reader_stream() -> ByteReaderStream:
    return ByteReaderStream.new(get_data())

## Returns `true` if the number of actual bytes read was smaller than the number
## of bytes available in the block header.
func is_too_short() -> bool:
    return get_declared_block_size() > get_actual_block_size()

## Creates an empty data block of size zero.
static func make_empty() -> DataBlock:
    var data = PackedByteArray([0])
    return DataBlock.new(ByteReaderStream.new(data))

## Skips a data block from the given stream and returns a number that specifies
## the amount of bytes that were skipt.
static func skip_stream(input_stream: ByteReaderStream) -> int:
    if input_stream.is_eof():
        return 0

    var block_size = input_stream.read_byte()

    input_stream.advance(block_size)
    return block_size

# Skips variable length blocks up to and including the next zero length block
# (block terminator)
static func skip_blocks(input_stream: ByteReaderStream):
    while DataBlock.skip_stream(input_stream) > 0:
        pass
