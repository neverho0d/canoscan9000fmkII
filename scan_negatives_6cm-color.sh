#!/bin/bash

if [ -z "$1" ]; then
	echo "no valid name for the film strip given"
	echo "Usage: $0 strip_name"
	exit 1
fi

# adjust as needed
WORKDIR="$HOME/scanning"
# most optimal for speed-quality
RESOLUTION=2400

# Normally, you don't need to change anything below this line
#----------------------------------------------------------------------------
# this script is prepared for 6cm color negative
TYPE="negative_6cm"

## scanning parameters
# MODE can be: auto|Color|Gray|48 bits color|16 bits gray|Lineart [Color]
MODE="Color"
echo ""
TARGETDIR="/home/psv/scanning/$TYPE/$1"
TARGETDIR_TIFF="/home/psv/scanning/$TYPE/$1/TIFF"
mkdir -p "$TARGETDIR"
mkdir -p "$TARGETDIR_TIFF"
echo "target directory for this slide magazine: $TARGETDIR"

echo "IS THE GLASS CLEAN?"

while true; do
	echo ""
	echo "to scan the next 3 slides: press enter"
	echo "OR enter slide count (1-3), then press enter"
	echo "OR if the magazine is done: press Ctrl-C"
	read frame_count

        STRIP_LEN=188
	MAX_FRAMES=3
        FRAMES=3
        case $frame_count in
                "1"|"2") FRAMES=$frame_count ;;
                "3"|"") ;;
                *) echo "Wrong frame count: $frame_count. Try again!" && continue ;;
        esac

	STRIP_LEN=$(($STRIP_LEN / $MAX_FRAMES * $FRAMES))
	
	TEMPDIR=$(mktemp -p /home/psv/scanning/tmp -d -t diascan.XXXXXX)
	echo "temporary directory for this slide magazine: $TEMPDIR"

	# scan the strip
	# this produces a set of TIFF files, an image per frame
	echo "Scanning..."
	scanimage -d pixma:04A9190D --source 'Transparency Unit' --resolution $RESOLUTION --format=tiff --mode $MODE -l 75 -t 22 -x 66 -y $STRIP_LEN \
	| convert tiff:- -crop 1x$FRAMES@\! +repage +adjoin $TEMPDIR/original_%d.tiff
	
	# now we'll go through all TIFFs and convert them to the proper JPEG file with some common settings
        # original TIFF will be kept in case we need some manual processing
	for file in `ls $TEMPDIR/original_*.tiff` ; do
		newfile=$(echo $file | sed -e 's#original_#edited_#' -e 's#tiff$#jpg#')
		echo "Converting TIFF to JPG"
		convert "$file" -contrast -fuzz 3% -trim -gamma 3 -modulate 100,250,100 -quality 100 "$newfile"
		TS=$(date +%F-%H%M%S)
		mv $file $TARGETDIR_TIFF/IMG-${TS}-original.tiff
		mv $newfile $TARGETDIR/IMG-${TS}-neg.jpg
		echo "Creating a positive $TARGETDIR/IMG-${TS}-edited.jpg"
		negative2positive $TARGETDIR/IMG-${TS}-neg.jpg $TARGETDIR/IMG-${TS}-edited.jpg
		rm $TARGETDIR/IMG-${TS}-neg.jpg
		sleep 1
	done
	
	rm -rf $TEMPDIR
done
