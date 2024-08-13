#! /bin/sh

# Check if ffmpeg is installed
if ! [ -x "$(command -v ffmpeg)" ]; then
  echo 'Error: ffmpeg is not installed.' >&2
  exit 1
fi

# Check if imagemagick is installed
if ! [ -x "$(command -v magick)" ]; then
  echo 'Error: imagemagick is not installed.' >&2
  exit 1
fi

# Check if firefox is installed
if ! [ -x "$(command -v firefox)" ]; then
  echo 'Error: firefox is not installed.' >&2
  exit 1
fi

# Check number of args
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <input_file> <title> <subtitle>"
  exit 1
fi

INPUT_FILE=$1
TITLE=$2
SUBTITLE=$3

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: File $INPUT_FILE not found."
  exit 1
fi

DURATION=$(ffmpeg -i $INPUT_FILE 2>&1 | grep "Duration" | awk '{print $2}')
if [ -z "$DURATION" ]; then
  echo "Error: Could not get duration of $INPUT_FILE."
  exit 1
fi

HH=$(echo $DURATION | cut -d: -f1)
MM=$(echo $DURATION | cut -d: -f2)
SS=$(echo $DURATION | cut -d: -f3 | cut -d. -f1)

RANDOM_HH=$((RANDOM % (HH+1)))
RANDOM_MM=$((RANDOM % (MM+1)))
RANDOM_SS=$((RANDOM % (SS+1)))

echo "Duration: $DURATION, selected frame: $RANDOM_HH:$RANDOM_MM:$RANDOM_SS"

ffmpeg -ss $RANDOM_HH:$RANDOM_MM:$RANDOM_SS -i $INPUT_FILE \
        -vframes 1 -y frame.png 2>/dev/null 1>/dev/null

# Resize and add blur
magick "frame.png" -resize 1280x720 -blur 0x8 "frame.png"

# Add title
input_image="frame.png"
output_image="frame.png"
font_path="the-bold-font.ttf"
font_size=100
text_color="white"

# Create a shadow image
magick -size 1280x720 \
        -define gradient:radii=600,70 \
        radial-gradient:black-none \
        ellipse.png

# Make the shadow semi-transparent
magick ellipse.png \
        -evaluate Multiply 0.7 \
        ellipse.png

# Add the shadow to the image
magick $input_image ellipse.png \
        -gravity center \
        -compose over \
        -composite \
        $output_image

rm ellipse.png

# Add title to the image
magick "$input_image" \
    -font "$font_path" \
    -pointsize "$font_size" \
    -fill "$text_color" \
    -gravity center \
    -annotate +0-40 "$TITLE" \
    "$output_image"

font_size=40

# Add subtitle to the image
magick "$input_image" \
    -font "$font_path" \
    -pointsize "$font_size" \
    -fill "$text_color" \
    -gravity center \
    -annotate +0+40 "$SUBTITLE" \
    "$output_image"

firefox "frame.png"

echo "Done"
