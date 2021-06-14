#!/bin/bash

cd "${0%/*}" # make sure we're in the right directory
if [ "$(basename $(realpath ..))" != "_release" ] ; then
  echo "Not in release directory; aborting"
  exit
fi

function deploy { # deploy target files from Stardust Core
  mkdir -p $(dirname "./$1") # create directory if it doesn't exist
  cp -R "../../StardustLib/$1" "./$1"
}

deploy interface.config.patch
deploy panes.config.patch

deploy interface/scripted/mmupgrade

deploy metagui.lua
deploy metagui/themes
deploy metagui/container.config
deploy metagui/containerstub.lua
deploy metagui/example.ui
deploy metagui/registry.json

deploy quickbar

deploy sys/metagui
deploy sys/quickbar
deploy sys/stardust/quickbar

# some select parts of Stardust Core's library files that can be useful for client-side things
deploy lib/stardust/color.lua
deploy lib/stardust/json.lua
deploy lib/stardust/rng.lua
deploy lib/stardust/augmentutil.lua
deploy lib/stardust/augmentdefs.config

# include tech input hooks because metaGUI works best with them
deploy lib/stardust/tech
deploy tech

# copy version from Stardust Core
jq --slurpfile v ../StardustLib/_metadata '.version = $v[0].version' ../../StardustLite/_metadata > ./_metadata
