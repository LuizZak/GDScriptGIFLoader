## Represents a byte of data in a GIF data stream which contains a number of data
## items encoded as bits.
class_name PackedField

var _bits: Array[bool] = []

func _init(data: int):
    for i in 8:
        var bit_shift := 7 - i
        var bit_value := (data >> bit_shift) & 1
        var bit := bit_value == 1
        _bits.append(bit)

## Gets the value of a single bit at a given index.
##
## Precondition: `index >= 0 and index < 8`
func get_bit(index: int) -> bool:
    assert(index >= 0 and index < 8, "Trying to read invalid bit index %d in PackedField" % [index])
    return _bits[index]

## Gets the value of one or more bits at a given index.
##
## Precondition: `index >= 0 and index + length < 8 and length > 0`
func get_bits(index: int, length: int) -> int:
    assert(index >= 0 and index + length <= 8 and length > 0, "Trying to read invalid bit indices %d+%d in PackedField" % [index, length])

    var result := 0
    var bit_shift := length - 1

    for i in range(index, index + length):
        var bit_value = int(_bits[i]) << bit_shift
        result += bit_value
        bit_shift -= 1

    return result
