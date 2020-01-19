#!/bin/bash

if [ -z "$1" ]; then
	echo "no valid name for the film strip given"
	echo "UsageL $0 strip_name"
	exit 1
fi

# adjust as needed
WORKDIR="$HOME/scanning"
# most optimal for speed-quality
RESOLUTION=2400

# Normally, you don't need to change the stuff below this line
#---------------------------------------------------------------------------
# this scrip is for 35mm BW film strips
TYPE="negative_35mm"

# MODE can be: auto|Color|Gray|48 bits color|16 bits gray|Lineart [Color]
MODE="Gray"

POINT_PER_MM=$(($RESOLUTION * 10 / 254))
GAP_MM=15
GAP_PX=$(($GAP_MM * $POINT_PER_MM))
echo ""
TARGETDIR="$WORKDIR/$TYPE/$1"
TARGETDIR_TIFF="$WORKDIR/$TYPE/$1/TIFF"
mkdir -p "$TARGETDIR"
mkdir -p "$TARGETDIR_TIFF"
echo "target directory for this film strip: $TARGETDIR"

echo "IS THE GLASS CLEAN?"

while true; do
	echo ""
	echo "to scan the next 6 frames: press enter"
	echo "OR enter frame count (1-6), then press enter"
	echo "OR if the magazine is done: press Ctrl-C"
	read frame_count  
	
	STRIP_LEN=226
	MAX_FRAMES=6
	FRAMES=6
	case $frame_count in
		"1"|"2"|"3"|"4"|"5") FRAMES=$frame_count ;;
		"6"|"") ;;
		*) echo "Wrong frame count: $frame_count. Try again!" && continue ;;
	esac
	
	STRIP_LEN=$(($STRIP_LEN / $MAX_FRAMES * $FRAMES))

	TEMPDIR=$(mktemp -p $WORKDIR/tmp -d -t diascan.XXXXXX)
	echo "temporary directory for this film strip: $TEMPDIR"


	# scan the strip
	# this produces a set of TIFF files, an image per frame
	scanimage -d pixma:04A9190D --source 'Transparency Unit' --resolution $RESOLUTION --format=tiff --mode $MODE -l 75 -t 22 -x 66 -y $STRIP_LEN \
	| convert tiff:- -crop 2x$FRAMES-$GAP_PX+0@\! +repage +adjoin -colorspace Gray $TEMPDIR/original_%d.tiff
	
	# now we'll go through all TIFFs and convert them to the proper JPEG file with some common settings
        # original TIFF will be kept in case we need some manual processing
	for file in `ls $TEMPDIR/original_*.tiff` ; do
		echo "converting $file"
		newfile=$(echo $file | sed -e 's#original_#edited_#' -e 's#tiff$#jpg#')
		convert "$file" -contrast -fuzz 3% -trim -gamma 3 -modulate 100,250,100 -quality 100 "$newfile"
		TS=$(date +%F-%H%M%S)
		mv $file $TARGETDIR_TIFF/IMG-${TS}-original.tiff
		mv $newfile $TARGETDIR/IMG-${TS}-neg.jpg
		echo "making positive $file"
		negative2positive $TARGETDIR/IMG-${TS}-neg.jpg $TARGETDIR/IMG-${TS}-edited.jpg
		rm $TARGETDIR/IMG-${TS}-neg.jpg
		sleep 1
	done
	
	rm -rf $TEMPDIR
	exit
done
