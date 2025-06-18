## The image data for a table based image consists of a sequence of
## sub-blocks, of size at most 255 bytes each, containing an index into
## the active color table, for each pixel in the image.
## Pixel indices are in order of left to right and from top to bottom.
## Each index must be within the range of the size of the active color
## table, starting at 0.
## See http://www.w3.org/Graphics/GIF/spec-gif89a.txt section 22
class_name TableBasedImageData

const MAX_STACK_SIZE := 4096
const NULL_CODE := -1

var _pixel_indices: PackedByteArray = []
var _lzw_minimum_code_size: int
var _error: Error

func _init(input_stream: ByteReaderStream, pixel_count: int) -> void:
    if pixel_count < 1:
        _error = Error.ERR_PARAMETER_RANGE_ERROR
        return

    _pixel_indices.resize(pixel_count)
    var next_available_code := 0 # The next code to be added to the dictionary
    var current_code_size := 0
    var in_code := 0
    var previous_code := 0
    var code := 0
    var datum := 0 # Temporary storage for codes read from the input stream
    var meaningful_bits_in_datum := 0 # Number of bits of useful information held in the datum variable
    var first_code := 0 # First code read from the stream since last clear code
    var index_in_data_block := 0
    var pixel_index := 0

    ## Number of bytes still to be extracted from the current data block
    var bytes_to_extract := 0

    var prefix := PackedInt32Array()
    prefix.resize(MAX_STACK_SIZE)
    var suffix := PackedByteArray()
    suffix.resize(MAX_STACK_SIZE)
    var pixel_stack: PackedByteArray = []
    pixel_stack.resize(pixel_count)
    var pixel_stack_index := 0

    _lzw_minimum_code_size = input_stream.read_byte()
    var clear_code := get_clear_code()
    var end_of_information := get_end_of_information()
    next_available_code = clear_code + 2
    previous_code = NULL_CODE
    current_code_size = get_initial_code_size()

    if clear_code >= MAX_STACK_SIZE:
        _error = Error.ERR_FILE_CORRUPT
        return

    code = 0
    while code < clear_code:
        suffix[code] = code

        code += 1

    #region Decode LZW image data

    # Initialise block to an empty data block. This will be overwritten
    # first time through the loop with a data block read from the input
    # stream.
    var block := DataBlock.make_empty()
    var block_data: PackedByteArray = []

    pixel_index = 0
    while pixel_index < pixel_count:
        if pixel_stack_index == 0:
            # There are no pixels in the stack at the moment so...

            if meaningful_bits_in_datum < current_code_size:
                # Then we don't have enough bits in the datum to make a code; we
                # need to get some more from the current data block, or we may
                # need to read another data block rom the input stream

                if bytes_to_extract == 0:
                    # Then we've extracted all the bytes from the current data
                    # block, so...

                    block = DataBlock.new(input_stream)
                    bytes_to_extract = block.get_actual_block_size()
                    block_data = block.get_data()

                    # Point to the first byte in the new data block
                    index_in_data_block = 0

                    if block.is_too_short():
                        # Then we've reached the end of the stream prematurely
                        break

                    if bytes_to_extract == 0:
                        # Then it's a block terminator, end of image data (this
                        # is a data block other than the first one)
                        break

                # Append the contents of the current byte in the data block to the
                # beginning of the datum
                datum += block_data[index_in_data_block] << meaningful_bits_in_datum

                # So we've now got 8 more bits of information in the datum.
                meaningful_bits_in_datum += 8

                # Point to the next byte in the data block
                index_in_data_block += 1

                # We've one less byte still to read from the data block now.
                bytes_to_extract -= 1

                # And carry on reading through the data block
                continue

            # Get the least significant bits from the read datum, up to the
            # maximum allowed by the current code size.
            code = datum & ((1 << current_code_size) - 1) # get_maximum_possible_code(current_code_size)

            # Drop the bits we've just extracted from the datum
            datum >>= current_code_size

            # Reduce the count of meaningful bits held in the datum
            meaningful_bits_in_datum -= current_code_size

            if code == end_of_information:
                # We've reached an explicit marker for the end of the image data.
                break

            if code > next_available_code:
                # We expect the code to be either one which is already in the
                # dictionary, or the next available one to be added. If it's
                # neither of these then abandon processing of the image.
                _error = Error.ERR_FILE_CORRUPT
                break

            if code == clear_code:
                # We can get a clear code at any point in the image data, this
                # is an instruction to reset the decoder and empty the dictionary
                # of codes.
                current_code_size = _lzw_minimum_code_size + 1 # get_initial_code_size()
                next_available_code = (1 << _lzw_minimum_code_size) + 2 # get_clear_code() + 2
                previous_code = NULL_CODE

                # Carry on reading from the input stream
                continue

            if previous_code == NULL_CODE:
                # This is the first code read since the start of the image data
                # or the most recent clear code.
                # There's no previously read code in memory yet, so get pixel
                # index for the current code and add it to the stack.
                pixel_stack[pixel_stack_index] = suffix[code]
                pixel_stack_index += 1
                previous_code = code
                first_code = code

                # And carry on to the next pixel
                continue

            in_code = code
            if code == next_available_code:
                pixel_stack[pixel_stack_index] = first_code
                pixel_stack_index += 1
                code = previous_code

            while code > clear_code:
                pixel_stack[pixel_stack_index] = suffix[code]
                pixel_stack_index += 1
                code = prefix[code]

            first_code = (suffix[code]) & 0xFF

            pixel_stack[pixel_stack_index] = first_code
            pixel_stack_index += 1

            # This fix is based off of ImageSharp's LzwDecoder.cs:
            # https://github.com/SixLabors/ImageSharp/blob/8899f23c1ddf8044d4dea7d5055386f684120761/src/ImageSharp/Formats/Gif/LzwDecoder.cs

            # Fix for Gifs that have 'deferred clear code' as per here:
            # https://bugzilla.mozilla.org/show_bug.cgi?id=55918
            if next_available_code < MAX_STACK_SIZE:
                prefix[next_available_code] = previous_code & 0xFFFF
                suffix[next_available_code] = first_code & 0xFF
                next_available_code += 1

                #if (next_available_code & get_maximum_possible_code(current_code_size)) == 0:
                if (next_available_code & ((1 << current_code_size) - 1)) == 0:
                    # We've reached the largest code possible for this size
                    if next_available_code < MAX_STACK_SIZE:
                        # So increase the code size by 1
                        current_code_size += 1

            previous_code = in_code

        # Pop all the pixels currently on the stack off, and add them to the return
        # value
        pixel_stack_index -= 1
        _pixel_indices[pixel_index] = pixel_stack[pixel_stack_index]
        pixel_index += 1

    if pixel_index < pixel_count:
        _error = Error.ERR_FILE_CORRUPT
        return

    #endregion

## Gets any error found during initialization.
## If no errors were found, returns `Error.OK`.
func get_error() -> Error:
    return _error

## Gets the array of indices to colors in the active color table, representing
## the pixels of a frame in a GIF data stream.
func get_pixel_indices() -> PackedByteArray:
    return _pixel_indices

## A special Clear code is defined which resets all compression /
## decompression parameters and tables to a start-up state.
## The value of this code is 2 ^ code size.
## For example if the code size indicated was 4 (image was 4 bits/pixel)
## the Clear code value would be 16 (10000 binary).
## The Clear code can appear at any point in the image data stream and
## therefore requires the LZW algorithm to process succeeding codes as
## if a new data stream was starting.
## Encoders should output a Clear code as the first code of each image
## data stream.
func get_clear_code() -> int:
    return 1 << _lzw_minimum_code_size

## Gets the size in bits of the first code to add to the dictionary.
func get_initial_code_size() -> int:
    return _lzw_minimum_code_size + 1

## Gets the code which explicitly marks the end of the image data in the stream.
func get_end_of_information() -> int:
    return get_clear_code() + 1

## Gets the highest possible code for the supplied code size - when
## all bits in the code are set to 1.
## This is used as a bitmask to extract the correct number of least
## significant bits from the datum to form a code.
func get_maximum_possible_code(current_code_size: int) -> int:
    return (1 << current_code_size) - 1
