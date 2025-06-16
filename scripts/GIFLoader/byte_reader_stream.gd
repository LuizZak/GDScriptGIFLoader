## A self-advanding stream of bytes that can be read and decoded.
class_name ByteReaderStream

var _buffer: PackedByteArray
var _offset: int

## Returns the count of available bytes remaining to be read.
var remaining_bytes: int:
    get:
        return _buffer.size() - _offset

func _init(buffer: PackedByteArray, offset: int = 0):
    self._buffer = buffer
    self._offset = offset

## Advances the stream by `value` bytes.
func advance(value: int) -> void:
    _offset += value

## Returns `true` if the current offset points past the end of the readable bytes
## of the underlying buffer.
func is_eof() -> bool:
    return _offset >= self._buffer.size()

## Returns `true` if the current offset + `advance` points past the end of the
## readable bytes of the underlying buffer.
##
## Precondition: `advance >= 0`.
func is_eof_at(advance: int) -> bool:
    assert(advance >= 0)

    return _offset + advance >= self._buffer.size()

## Alias for `read_u8`.
##
## Reads an unsinged 8-bit integer and moves the stream forward by 1 byte.
func read_byte() -> int:
    return read_u8()

## Alias for `read_u16_little_endian`.
##
## Reads an unsigned 16-bit integer encoded as least-significant byte first,
## and moves the stream forward by 2 bytes.
func read_short() -> int:
    return read_u16_little_endian()

## Reads an unsinged 8-bit integer and moves the stream forward by 1 byte.
func read_u8() -> int:
    var v = self._buffer.decode_u8(_offset)
    advance(1)
    return v

## Reads a signed 8-bit integer and moves the stream forward by 1 byte.
func read_s8() -> int:
    var v = self._buffer.decode_s8(_offset)
    advance(1)
    return v

## Reads an unsigned 16-bit integer and moves the stream forward by 2 bytes.
func read_u16() -> int:
    var v = self._buffer.decode_u16(_offset)
    advance(2)
    return v

## Reads an unsigned 16-bit integer encoded as least-significant byte first,
## and moves the stream forward by 2 bytes.
func read_u16_little_endian() -> int:
    var low = read_u8()
    var high = read_u8() << 8
    return high | low

## Reads a signed 16-bit integer and moves the stream forward by 2 bytes.
func read_s16() -> int:
    var v = self._buffer.decode_s16(_offset)
    advance(2)
    return v

## Reads an signed 16-bit integer encoded as least-significant byte first,
## and moves the stream forward by 2 bytes.
func read_s16_little_endian() -> int:
    var low = read_u8()
    var high = read_u8() << 8
    if low | high < 0:
        return -1
    return high | low

## Reads an unsigned 32-bit integer and moves the stream forward by 4 bytes.
func read_u32() -> int:
    var v = self._buffer.decode_u32(_offset)
    advance(4)
    return v

## Reads a signed 32-bit integer and moves the stream forward by 4 bytes.
func read_s32() -> int:
    var v = self._buffer.decode_s32(_offset)
    advance(4)
    return v

## Reads an unsigned 64-bit integer and moves the stream forward by 8 bytes.
func read_u64() -> int:
    var v = self._buffer.decode_u64(_offset)
    advance(8)
    return v

## Reads a signed 64-bit integer and moves the stream forward by 8 bytes.
func read_s64() -> int:
    var v = self._buffer.decode_s64(_offset)
    advance(8)
    return v

## Reads an arbitrary chunk of data from this byte reader and moves the stream
## forward by `size` bytes.
func read_data(size: int) -> PackedByteArray:
    var v = self._buffer.slice(_offset, _offset + size)
    advance(size)
    return v

## Decodes the next `length` bytes from the stream as an ASCII-encoded String.
func read_ascii(length: int) -> String:
    var data = read_data(length)
    return data.get_string_from_ascii()
