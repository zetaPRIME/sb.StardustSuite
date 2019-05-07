#!/bin/bash
echo "Exporting to PNG..."
{ # first some bash+Scheme insanity, adapted from http://billauer.co.il/blog/2009/07/gimp-xcf-jpg-jpeg-convert-bash-script/
  cat <<EOF
(define (convert-xcf-to-png filename outfile)
  (let* (
	 (image (car (gimp-file-load RUN-NONINTERACTIVE filename filename)))
	 (drawable (car (gimp-image-merge-visible-layers image CLIP-TO-IMAGE)))
	 )
    (file-png-save2 RUN-NONINTERACTIVE image drawable outfile outfile FALSE 9 TRUE FALSE FALSE FALSE FALSE FALSE TRUE)
    (gimp-image-delete image) ; ... or the memory will explode
    )
  )

(gimp-message-set-handler 1) ; Messages to standard output
EOF

  for i in *.xcf; do
    echo "(gimp-message \"$i\")"
    echo "(convert-xcf-to-png \"$i\" \"${i%%.xcf}.png\")"
  done

  echo "(gimp-quit 0)"
} | gimp -i -b - > /dev/null # silence, mortal!

echo "Applying color substitutions..."

palswap () {
  convert "$1" \
    -fill '#dafafafa' -opaque '#ffffff' \
    -fill '#caeaeafa' -opaque '#fff8b5' \
    -fill '#badadafa' -opaque '#fde03f' \
    -fill '#aacacafa' -opaque '#f6b919' \
    +set date:create +set date:modify \
    "$1"
}

palswap body.png
palswap head.png
palswap frontarm.png
palswap backarm.png

\cp body.png malebody.png
\cp body.png femalebody.png
\cp head.png malehead.png
\cp head.png femalehead.png
