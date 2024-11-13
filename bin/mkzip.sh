#!/bin/bash
mkdir -p build/vl2
cp build/vlamits2.* build/vl2
mv build/vl2/vlamits2.html build/vl2/index.html
cd build/vl2
rm vl2.zip
zip vl2.zip vlamits2* index.html