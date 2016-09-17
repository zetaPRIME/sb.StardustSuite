#!/bin/bash

cmthash=$(git rev-parse --short HEAD)

# your path will likely be different, but whatever
#alias asset_packer="../../../win32/asset_packer.exe"
asset_packer () {
  ../../../win32/asset_packer.exe "$@"
}

function pack {
    echo $1
    rm -rf ./_release/$1
    cp f ./$1 ./_release/$1
    ./jq ".version |= . + \"-$cmthash\"" ./$1/_metadata > ./_release/$1/_metadata
    asset_packer ./_release/$1/ ./_release/$1.pak
}

mkdir -p ./_release/

pack StardustLib
pack StardustTweaks
pack StarTech
