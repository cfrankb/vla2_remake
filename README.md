Remake of The Vlamits 2 (1995) from assembly source to portable C++ (2024).

![level07![Screenshot_2024-06-21_16-05-54]](https://i.imgur.com/IojHEhl.png)

## Building the runtime

### Online version


The online version requires SDL2, zlib and Emscripten.


<b> Build cs3 runtime</b>

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

https://cfrankb.com/games/ems/vlamits2.html
