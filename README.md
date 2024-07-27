## Vlamits2 Runtime SDL

Remake of The Vlamits 2 (1995) from assembly source to portable C++ (2024).

![level07![Screenshot_2024-06-21_16-05-54]](techdocs/images/Screenshot_2024-06-26_22-36-12.png)

## Building the runtime

### Online version

The online version requires SDL2, zlib and Emscripten.

<b> Build vlamits2 runtime</b>

First install emscripten : https://emscripten.org/index.html

Run these commands

```
$ python bin/gen.py emsdl
$ emmake make
```

<b>Launch the application</b>

```
$ emrun build/vlamits2.html
```

### Map Editor

TBD

### Play online

Use cursor keys to move the player and SHIFT/SPACE to jump.

https://cfrankb.com/games/ems/vlamits2.html
