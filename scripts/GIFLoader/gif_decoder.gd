class_name GifDecoder

## Plaintext label - identifies the current block as a plain text extension.
const CODE_PLAINTEXT_LABEL := 0x01
## Extension introducer - identifiees the start of an extension block.
const CODE_EXTENSION_INTRODUCER := 0x21
## Image separator - identifies the start of an Image Descriptor.
const CODE_IMAGE_SEPARATOR := 0x2C
## Trailer - This is a single-field block indicating the end of the GIF data stream.
const CODE_TRAILER := 0x38
## Graphic control label - identifies the current block as a Graphic Control
## Extension.
const CODE_GRAPHIC_CONTROL_LABEL := 0xF9
## Comment lable - identifies the current block as a comment extension.
const CODE_COMMENT_LABEL := 0xFE
## Application extension label - identifies the current block as a Application
## Extension.
const CODE_APPLICATION_EXTENSION_LABEL := 0xFF

var _reader: ByteReaderStream
var _gif_header: GifHeader
var _lsd: LogicalScreenDescriptor
var _last_no_disposal_frame: GifFrame
var _frame_delays: PackedInt32Array = []
var _gct: ColorTable
var _netscape_extension: NetscapeExtension
var _application_extensions: Array[ApplicationExtension]
var _frames: Array[GifFrame]

var _error: Error

func _init(data: PackedByteArray) -> void:
    _reader = ByteReaderStream.new(data)

    _gif_header = GifHeader.new(_reader)
    if _gif_header.get_error():
        _error = _gif_header.get_error()
        return

    _lsd = LogicalScreenDescriptor.new(_reader)
    if _lsd.get_error():
        _error = _lsd.get_error()
        return

    if _lsd.has_global_color_table():
        _gct = ColorTable.new(_reader, _lsd.global_color_table_size())
        if _gct.get_error():
            _error = _gct.get_error()
            return

    if _error == Error.OK:
        _read_contents(_reader)

## Gets the error emitted by the latest call to `decode`.
## If no errors were found and the file was successfully loaded, `Error.OK` is
## returned, instead.
func get_error() -> Error:
    return _error

## Gets the array of frames that were decoded.
func get_frames() -> Array[GifFrame]:
    return _frames

## Gets the frames that were decoded within a SpriteFrames instance.
func get_sprite_frames() -> SpriteFrames:
    var sprite_frames := SpriteFrames.new()

    var average_delay := 0
    for frame in _frames:
        average_delay += frame.get_delay()

    average_delay /= _frames.size()

    var fps := 100.0 / average_delay

    sprite_frames.set_animation_speed(&"default", fps)

    for frame in _frames:
        var texture := ImageTexture.create_from_image(frame.get_image())
        sprite_frames.add_frame(&"default", texture, float(frame.get_delay()) / average_delay)

    return sprite_frames

func _read_contents(input_stream: ByteReaderStream) -> void:
    var done := false
    var last_gce: GraphicControlExtension = null

    while not done:
        if input_stream.is_eof():
            _error = Error.ERR_FILE_CORRUPT
            break

        var code := input_stream.read_byte()

        match code:
            CODE_IMAGE_SEPARATOR:
                _add_frame(input_stream, last_gce)

            CODE_EXTENSION_INTRODUCER:
                code = input_stream.read_byte()

                match code:
                    CODE_PLAINTEXT_LABEL:
                        DataBlock.skip_blocks(input_stream)

                    CODE_GRAPHIC_CONTROL_LABEL:
                        last_gce = GraphicControlExtension.new(input_stream)

                    CODE_COMMENT_LABEL:
                        DataBlock.skip_blocks(input_stream)

                    CODE_APPLICATION_EXTENSION_LABEL:
                        var ext := NetscapeExtension.new(input_stream)
                        _netscape_extension = ext

                    _:
                        DataBlock.skip_blocks(input_stream)

            CODE_TRAILER:
                done = true
                pass

            0x00:
                pass

            _:
                _error = Error.ERR_FILE_CORRUPT

func _add_frame(input_stream: ByteReaderStream, last_gce: GraphicControlExtension) -> void:
    var previous_frame: GifFrame = null
    if not _frames.is_empty():
        previous_frame = _frames[-1]

    # Setup the frame delay
    if last_gce != null:
        _frame_delays.append(last_gce.delay_time())
    else:
        _frame_delays.append(0)

    var frame := GifFrame.new(
        input_stream,
        _lsd,
        _gct,
        last_gce,
        previous_frame,
        _last_no_disposal_frame,
        _frames.size()
    )
    if (
        last_gce == null ||
        last_gce.disposal_method() == GraphicControlExtension.DisposalMethod.DO_NOT_DISPOSE ||
        last_gce.disposal_method() == GraphicControlExtension.DisposalMethod.DO_NOT_DISPOSE
        ):
        _last_no_disposal_frame = frame

    _frames.append(frame)
