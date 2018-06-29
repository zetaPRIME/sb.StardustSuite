#!/bin/bash

cd "${0%/*}" # make sure we're in the right directory

while getopts ":s" opt; do
  case $opt in
    s)
      _steamupload=1
      _steamuser=$(cat ./steamuser)
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

cmthash=$(git rev-parse --short HEAD)

unameOut="$(uname -s)"
case "${unameOut}" in
  CYGWIN*)  ;& # windows... I don't know where the heck you'll have this
  MINGW*)   ;;
  *)        _asset_packer="$HOME/.local/share/Steam/steamapps/common/Starbound/linux/asset_packer" ;;
esac

asset_packer () {
  "$_asset_packer" "$@"
}

function pack {
  echo $1
  rm -rf ./_release/$1/
  mkdir -p ./_release/$1/
  cp -Rf ./$1/* ./_release/$1/
  jq ".version |= . + \"-$cmthash\"" ./$1/_metadata > ./_release/$1/_metadata
  asset_packer ./_release/$1/ ./_release/$1.pak
  if [ ! -z "$_steamupload" ] ; then
    echo Uploading to Steam...
    steamcmd +login $_steamuser +workshop_build_item ./$1.vdf +exit
  fi
}

# mkdir -p ./_release/

pack StardustLib
pack StardustTweaks
pack StarTech
