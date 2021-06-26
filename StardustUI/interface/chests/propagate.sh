#!/usr/bin/env bash

cd "${0%/*}" # make sure we're in the right directory
function variant {
  cp "./chest9.config.patch" "./chest$1.config.patch"
}

variant 1
variant 12
variant 16
variant 20
variant 24
variant 32
variant 40
variant 48
variant 56
variant 64
variant 72
variant 80
variant 90
variant 91
variant 100
variant 110
variant 120
variant 130
variant 140
variant 150
variant 160
variant 180
variant 200
variant 300
variant 540
variant 666
