# GDScriptGIFLoader

A native GDScript GIF file loader.

Loads files into `SpriteFrames` ready to be used by `AnimatedSprite2D`.

Example usage:

```gdscript
var file = FileAccess.open('user://some_gif_file.gif', FileAccess.READ)
if file == null:
    return

var buffer = file.get_buffer(file.get_length())
var gif_decoder = GifDecoder.new(buffer)

animated_sprite.sprite_frames = gif_decoder.get_sprite_frames()
animated_sprite.play(&"default")
```

Note: Performance is pretty poor even for small GIFs.
