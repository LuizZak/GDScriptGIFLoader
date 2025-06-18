## The header section of a Graphics Interchange Format stream.
## See http://www.w3.org/Graphics/GIF/spec-gif89a.txt section 17.
##
## The Header identifies the GIF Data Stream in context. The Signature
## field marks the beginning of the Data Stream, and the Version field
## identifies the set of capabilities required of a decoder to fully
## process the Data Stream.
## This block is REQUIRED; exactly one Header must be present per Data
## Stream.
class_name GifHeader

var _signature: String
var _gif_version: String
var _error: Error

func _init(input_stream: ByteReaderStream) -> void:
    if input_stream.remaining_bytes < 6:
        _error = Error.ERR_FILE_UNRECOGNIZED
        return

    _signature = input_stream.read_ascii(3)
    if _signature != "GIF":
        _error = Error.ERR_FILE_UNRECOGNIZED
        return

    _gif_version = input_stream.read_ascii(3)

## Gets any error found during initialization.
## If no errors were found, returns `Error.OK`.
func get_error() -> Error:
    return _error

## Gets the signature of the GIF file. Always `"GIF"` for valid GIF files.
func get_signature() -> String:
    return _signature

## Gets the GIF file version signature.
func get_gif_version() -> String:
    return _gif_version
