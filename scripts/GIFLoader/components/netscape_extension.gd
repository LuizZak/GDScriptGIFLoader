## An application extension which controls the number of times an animation
## should be displayed.
##
## See http://www.let.rug.nl/~kleiweg/gif/netscape.html for format
class_name NetscapeExtension
extends ApplicationExtension

var _loop_count: int

func _save_data(identification_block: DataBlock, application_data: Array[DataBlock]):
    super._save_data(identification_block, application_data)

    for block in application_data:
        if block.get_actual_block_size() == 0:
            break

        # The first byte in a Netscape application extension data block should
        # be 1. Ignore if anything else.
        var reader = block.get_data_as_byte_reader_stream()
        if block.get_actual_block_size() > 2 && reader.read_byte() == 1:
            _loop_count = reader.read_short()

## Number of times to repeat the frames of the animation. 0 to repeat indefinitely,
## -1 to not repeat.
func loop_count() -> int:
    ## TODO: Test values of -1 to ensure reader.read_short() above reads negative
    ## values appropriately.
    return _loop_count
