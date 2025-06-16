## The Application Extension contains application-specific information;
## it conforms with the extension block syntax, and its block label is
## 0xFF.
##
## See http://www.w3.org/Graphics/GIF/spec-gif89a.txt section 26.
class_name ApplicationExtension

var _identification_block: DataBlock
var _application_identifier: String
var _application_authentication_code: String
var _application_data: Array[DataBlock]
var _error: Error

func _init(input_stream: ByteReaderStream):
    var identification_block = DataBlock.new(input_stream)
    var application_data: Array[DataBlock] = []

    if not input_stream.is_eof():
        var this_block: DataBlock

        while not input_stream.is_eof():
            this_block = DataBlock.new(input_stream)
            application_data.append(this_block)

            if this_block.get_declared_block_size() == 0:
                break

    _save_data(identification_block, application_data)

## Gets any error found during initialization.
## If no errors were found, returns `Error.OK`.
func get_error() -> Error:
    return _error

func _save_data(identification_block: DataBlock, application_data: Array[DataBlock]):
    _identification_block = identification_block

    if _identification_block.get_declared_block_size() != 11:
        _error = Error.ERR_FILE_CORRUPT
        return

    var stream = _identification_block.get_data_as_byte_reader_stream()

    _application_identifier = stream.read_ascii(8)
    _application_authentication_code = stream.read_ascii(3)

    _application_data = application_data
