#!/bin/bash

if [ -z "$1" ]; then
	echo "no valid name for this set of slides"
	echo "Usage: $0 strip_name"
	exit 1
fi

# adjust as needed
WORKDIR="$HOME/scanning"
# most optimal for speed-quality
RESOLUTION=2400
        
# Normally, you don't need to change anything below this line
#----------------------------------------------------------------------------
# this script is prepared for 35mm color negative
TYPE="slide"

## scanning parameters
# MODE can be: auto|Color|Gray|48 bits color|16 bits gray|Lineart [Color]
MODE="Color"

echo ""
TARGETDIR="$WORKDIR/$TYPE/$1"
TARGETDIR_TIFF="$WORKDIR/$TYPE/$1/TIFF"
mkdir -p "$TARGETDIR"
mkdir -p "$TARGETDIR_TIFF"
echo "target directory for this slide set: $TARGETDIR"

echo "IS THE GLASS CLEAN?"

while true; do
	echo ""
	echo "to scan the next 4 slides: press enter"
	echo "OR enter slide count (1-4), then press enter"
	echo "OR if the magazine is done: press Ctrl-C"
	read imagecount
	
        STRIP_LEN=204
        MAX_FRAMES=4
        FRAMES=4
        case $frame_count in
                "1"|"2"|"3") FRAMES=$frame_count ;;
                "4"|"") ;;
                *) echo "Wrong slide count: $frame_count. Try again!" && continue ;;
        esac
   
	STRIP_LEN=$((36 + 56 * ($FRAMES - 1)))

	TEMPDIR=$(mktemp -p $WORKDIR/tmp -d -t diascan.XXXXXX)
	echo "temporary directory for this slide magazine: $TEMPDIR"

	# scan the slide set
        # this produces a set of TIFF files, an image per frame
	if [ "$imagecount" == "1" ]; then
		scanimage -d pixma:04A9190D --source 'Transparency Unit' --resolution $RESOLUTION --format=tiff --mode Color -l 90 -t 32 -x 38 -y $STRIP_LEN >$TEMPDIR/original_0.tiff
	else
		scanimage -d pixma:04A9190D --source 'Transparency Unit' --resolution $RESOLUTION --format=tiff --mode Color -l 90 -t 32 -x 38 -y $STRIP_LEN | convert tiff:- -crop 1x$FRAMES-0-850@\! +repage +adjoin $TEMPDIR/original_%d.tiff
	fi
	
	# now we'll go through all TIFFs and convert them to the proper JPEG file with some common settings
        # original TIFF will be kept in case we need some manual processing
	for file in `ls $TEMPDIR/original_*.tiff` ; do
		newfile=$(echo $file | sed -e 's#original_#edited_#' -e 's#tiff$#jpg#')
		convert "$file" -contrast -fuzz 3% -trim -gamma 3 -modulate 100,250,100 -quality 100 "$newfile"
		TS=$(date +%F-%R:%S)
		mv $file $TARGETDIR_TIFF/IMG-${TS}-original.tiff
		mv $newfile $TARGETDIR/IMG-${TS}-edited.jpg
		sleep 1 # to provide name difference
	done
	
	rm -rf $TEMPDIR
done
