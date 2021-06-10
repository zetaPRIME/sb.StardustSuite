#!/bin/bash

cd "${0%/*}" # make sure we're in the right directory
if [ "$(basename $(realpath ..))" != "_release" ] ; then
  echo "Not in release directory; aborting"
  exit
fi

# grab commit hash
cmthash=$(git rev-parse --short HEAD)

# copy version from Stardust Core
jq --slurpfile v ../../StardustLib/_metadata --arg cmt "-$cmthash" '.version = $v[0].version + $cmt' ../../StardustLibPost/_metadata > ./_metadata
