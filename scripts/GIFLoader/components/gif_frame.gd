## A single image frame from a GIF file.
class_name GifFrame

var _index: int
var _image: Image
var _delay: int
var _expects_user_input: bool
var _position: Vector2i
var _local_color_table: ColorTable
var _extension: GraphicControlExtension
var _image_descriptor: ImageDescriptor
var _background_color: Color
var _logical_screen_descriptor: LogicalScreenDescriptor
var _global_color_table: ColorTable
var _graphic_control_extension: GraphicControlExtension
var _previous_frame: GifFrame
var _previous_frame_but1: GifFrame
var _error: Error

func _init(
    input_stream: ByteReaderStream,
    logical_screen_descriptor: LogicalScreenDescriptor,
    global_color_table: ColorTable,
    graphic_control_extension: GraphicControlExtension,
    previous_frame: GifFrame,
    previous_frame_but1: GifFrame,
    index: int
):
    _index = index
    _logical_screen_descriptor = logical_screen_descriptor
    _global_color_table = global_color_table
    _graphic_control_extension = graphic_control_extension
    _previous_frame = previous_frame
    _previous_frame_but1 = previous_frame_but1

    _decode(input_stream)

## Gets any error found during initialization.
## If no errors were found, returns `Error.OK`.
func get_error() -> Error:
    return _error

## Returns the decoded image for this frame.
func get_image() -> Image:
    return _image

## Returns the computed delay for this frame.
func get_delay() -> int:
    return _delay

func _decode(input_stream: ByteReaderStream) -> void:
    _extension = _graphic_control_extension
    var transparent_color_index = _graphic_control_extension.transparent_color_index()

    var image_descriptor = ImageDescriptor.new(input_stream)

    var background_color = Color.from_rgba8(0, 0, 0, 0)

    var active_color_table: ColorTable
    if image_descriptor.has_local_color_table():
        _local_color_table = ColorTable.new(input_stream, image_descriptor.local_color_table_size())
        active_color_table = _local_color_table
    else:
        if _global_color_table == null:
            _error = Error.ERR_FILE_CORRUPT
            return

        active_color_table = _global_color_table
        if _logical_screen_descriptor.background_color_index() == transparent_color_index:
            background_color = Color.from_rgba8(0, 0, 0, 0)

    # Decode pixel data
    var pixel_count = image_descriptor.size().x * image_descriptor.size().y
    var tbid = TableBasedImageData.new(input_stream, pixel_count)
    if tbid.get_pixel_indices().is_empty():
        _error = Error.ERR_FILE_CORRUPT
        return

    # Skip any remaining blocks up to the next block terminator (in case there
    # is any surplus data before the next frame)
    DataBlock.skip_blocks(input_stream)

    if _graphic_control_extension != null:
        _delay = _graphic_control_extension.delay_time()

    _image_descriptor = image_descriptor
    _background_color = background_color
    _image = _create_image(
        tbid,
        _logical_screen_descriptor,
        image_descriptor,
        active_color_table,
        _graphic_control_extension,
        _previous_frame,
        _previous_frame_but1
    )

func _create_image(
    image_data: TableBasedImageData,
    lsd: LogicalScreenDescriptor,
    id: ImageDescriptor,
    active_color_table: ColorTable,
    gce: GraphicControlExtension,
    previous_frame: GifFrame,
    previous_frame_but1: GifFrame,
) -> Image:
    var base_image := _get_base_image(previous_frame, previous_frame_but1, lsd, gce, active_color_table)

    var _pass := 1
    var interlace_row_increment := 8
    var interlace_row_number := 0
    var has_transparent := gce.has_transparent_color()
    var transparent_color := gce.transparent_color_index()
    var logical_width := lsd.screen_size().x
    var logical_height := lsd.screen_size().y

    var image_x := id.position().x
    var image_y := id.position().y
    var image_width := id.size().x
    var image_height := id.size().y
    var is_interlaced := id.is_interlaced()
    var pixel_indices := image_data.get_pixel_indices()
    var num_colors := active_color_table.get_length()
    var colors := active_color_table.get_color_table()

    assert(base_image.get_format() == Image.FORMAT_RGBA8)
    var raw_image_data := base_image.get_data()

    for i in range(image_height):
        var pixel_row_number := i
        if is_interlaced:
            if interlace_row_number >= image_height:
                _pass += 1
                match _pass:
                    2:
                        interlace_row_number = 4
                    3:
                        interlace_row_number = 2
                        interlace_row_increment = 4
                    4:
                        interlace_row_number = 1
                        interlace_row_increment = 2

            pixel_row_number = interlace_row_number
            interlace_row_number += interlace_row_increment

        # Color in the pixels for this row
        pixel_row_number += image_y
        if pixel_row_number >= logical_height:
            continue

        var k := pixel_row_number * logical_width
        var dx := k + image_x # Start of line in dest
        var dlim := dx + image_width # End of dest line

        if (k + logical_width) < dlim:
            dlim = k + logical_width # Past dest edge

        var sx := i * image_width # Start of line in source

        dx *= 4
        dlim *= 4

        while dx < dlim:
            var index_in_color_table := pixel_indices[sx]
            sx += 1

            # Set this pixel's color if its index isn't the transparent color
            # index, or if this frame doesn't have a transparent color
            if not has_transparent or index_in_color_table != transparent_color:
                if index_in_color_table < num_colors:
                    var color := colors[index_in_color_table]

                    raw_image_data[dx] = (color >> 24) & 0xFF
                    raw_image_data[dx + 1] = (color >> 16) & 0xFF
                    raw_image_data[dx + 2] = (color >> 8) & 0xFF
                    raw_image_data[dx + 3] = color & 0xFF

            dx += 4

    base_image.set_data(logical_width, logical_height, false, Image.FORMAT_RGBA8, raw_image_data)

    return base_image

func _get_base_image(
    previous_frame: GifFrame,
    previous_frame_but1: GifFrame,
    lsd: LogicalScreenDescriptor,
    gce: GraphicControlExtension,
    act: ColorTable
) -> Image:
    var previous_disposal_method: GraphicControlExtension.DisposalMethod

    if previous_frame == null:
        previous_disposal_method = GraphicControlExtension.DisposalMethod.NOT_SPECIFIED
    else:
        previous_disposal_method = previous_frame._graphic_control_extension.disposal_method()

        if previous_disposal_method == GraphicControlExtension.DisposalMethod.RESTORE_TO_PREVIOUS and previous_frame_but1 == null:
            previous_disposal_method = GraphicControlExtension.DisposalMethod.RESTORE_TO_BACKGROUND_COLOR

    var base_image: Image
    var width := lsd.screen_size().x
    var height := lsd.screen_size().y
    var background_color_index: int = lsd._background_color_index
    if previous_frame != null:
        background_color_index = previous_frame._logical_screen_descriptor._background_color_index
    var transparent_color_index: int = gce.transparent_color_index()
    if previous_frame != null:
        transparent_color_index = previous_frame._graphic_control_extension.transparent_color_index()

    if previous_frame != null:
        if previous_frame._local_color_table != null:
            act = previous_frame._local_color_table
        else:
            act = previous_frame._global_color_table

    base_image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)

    if previous_frame == null or previous_frame._image == null:
        base_image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
    else:
        base_image = previous_frame.get_image().duplicate()

    match previous_disposal_method:
        GraphicControlExtension.DisposalMethod.DO_NOT_DISPOSE:
            pass

        GraphicControlExtension.DisposalMethod.RESTORE_TO_BACKGROUND_COLOR:
            var background_color: Color
            if background_color_index == transparent_color_index:
                background_color = Color.from_rgba8(0, 0, 0, 0)
            else:
                if background_color_index < act.get_length():
                    background_color = act.get_color(background_color_index)
                else:
                    background_color = Color.from_rgba8(0, 0, 0)

            # Adjust transparency
            background_color.a = 0.0

            if previous_frame._image_descriptor != null:
                base_image.fill_rect(
                    Rect2i(previous_frame._image_descriptor.position(), previous_frame._image_descriptor.size()),
                    background_color
                )

        GraphicControlExtension.DisposalMethod.RESTORE_TO_PREVIOUS:
            if previous_frame_but1 != null && previous_frame_but1._image != null:
                base_image = previous_frame_but1._image.duplicate()
            elif previous_frame != null && previous_frame._image != null:
                base_image = previous_frame._image.duplicate()

    return base_image
