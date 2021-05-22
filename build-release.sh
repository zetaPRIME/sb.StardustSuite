#!/bin/bash

cd "${0%/*}" # make sure we're in the right directory

while getopts ":s" opt; do
  case $opt in
    s)
      _steamupload=1
      _steamuser=$(cat ./steamuser)
      #sudo true # elevate ahead of time
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

confirm () {
  read -p "$1 [y/n] " -n 1 -r
  echo #
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    return 0
  fi
  return 1
}

function pack {
  echo $1
  rm -rf ./_release/$1/
  mkdir -p ./_release/$1/
  cp -Rf ./$1/* ./_release/$1/
  cp -f ./LICENSE.md ./_release/$1/
  jq ".version |= . + \"-$cmthash\"" ./$1/_metadata > ./_release/$1/_metadata
  asset_packer ./_release/$1/ ./_release/$1.pak
  if [ ! -z "$_steamupload" ] ; then
    # skip if set to not upload to steam
    if [ -f "./$1/_no_steam" ] ; then
      return
    fi
    # confirm upload
    if ! confirm "Upload $1 to Steam?" ; then
      return
    fi
    echo Uploading...
    
    mkdir -p ./_release/tmp/upload
    cp ./_release/$1.pak ./_release/tmp/upload/contents.pak
    if [ "$1" == "StardustLib" ] ; then
      cp ./_release/StardustLibPost.pak ./_release/tmp/upload/post.pak
    fi
    
    # gather info from metadata files
    local md="./$1/_metadata"
    local title=$(jq -r '.friendlyName' $md)
    local cid=$(jq -r '.steamContentId' $md)
    local version=$(jq -r '.version' $md | sed "s/\\\"/''/g")
    
    # start building the vdf
    local vdf="./_release/tmp/.vdf" ; touch $vdf
    # get the easy stuff out of the way
    printf "\"workshopitem\"{\"appid\"\"211820\"\"publishedfileid\"\"$cid\"\"title\"\"$title\"\"contentfolder\"\"$(realpath ./_release/tmp/upload)\"" >> $vdf
    # add preview image if present
    if [ -f "./$1/_previewimage" ] ; then printf "\"previewfile\"\"$(realpath ./$1/_previewimage)\"" >> $vdf ; fi
    # handle hidden parameter
    if jq -re '.hidden' $md > /dev/null ; then printf "\"visibility\"\"2\"" >> $vdf ; else printf "\"visibility\"\"0\"" >> $vdf ; fi
    # description!
    if [ -f "./$1/_steam_description" ] ; then
      printf "\"description\"\"$(sed "s/\\\"/''/g" ./$1/_steam_description)\"" >> $vdf
    else
      printf "\"description\"\"$(jq -r '.description' $md | sed "s/\\\"/''/g")\"" >> $vdf
    fi
    # changelog
    printf "\"changenote\"\"[b]$version[/b]\nCheck git releases for more info:\n" >> $vdf
    printf "https://github.com/zetaPRIME/sb.StardustSuite/releases" >> $vdf
    printf "\"}" >> $vdf # and cap off
    
    # actually upload mod!
    steamcmd +login $_steamuser +workshop_build_item $(realpath $vdf) +exit
    echo # force newline that steamcmd doesn't print
    rm -rf ./_release/tmp
  fi
}

# mkdir -p ./_release/

pack StardustLibPost
pack StardustLib
#pack StardustTweaks
pack StarTech
