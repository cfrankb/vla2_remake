#!/bin/bash
BIN=vlamits2
mkdir -p ./build/final
rm -f ./build/final/*
cp ./build/$BIN.* ./build/final
gzip  ./build/final/*.data ./build/final/*.wasm
mv ./build/final/$BIN.data.gz ./build/final/$BIN.data
mv ./build/final/$BIN.wasm.gz ./build/final/$BIN.wasm
cat src/template/footer.html >> ./build/final/$BIN.html
