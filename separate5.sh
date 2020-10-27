#!/bin/bash

#     A script for using spleeter with audio of any length
#     and with limited RAM on the processing machine
#
#     Author: Amaury Bodet
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.

# activate (mini)conda
# source ~/miniconda3/etc/profile.d/conda.sh
# conda activate

FILE="$1"
 
# failsafe - exit if no file is provided as argument
[ "$FILE" == "" ] && exit

NAME="${FILE%.*}"
EXT=$(printf "$FILE" | awk -F . '{print $NF}')

# split the audio file in 30s parts
ffmpeg -i "$FILE" -f segment -segment_time 30 -c copy "$NAME"-%03d.$EXT

# do the separation on the parts
spleeter separate -i "$NAME"-* -p spleeter:5stems -m -B tensorflow -o separated

# create output folder
mkdir -p separated/"$NAME"

# save and change IFS
OLDIFS=$IFS
IFS=$'\n'

# read all file name into an array (without .mp3/wav/... extension)
fileArray=($(find $NAME-* -type f | sed 's/\.[^.]*$//'))

# keep a copy of the array for cleanup later
fileArrayOrig=($(find $NAME-* -type f | sed 's/\.[^.]*$//'))

# prepend separated/ to each array element
fileArray=("${fileArray[@]/#/separated/}")
 
# restore it
IFS=$OLDIFS

# append /vocals.wav to each element and create arrays for the stems
fileArrayVocals=("${fileArray[@]/%//vocals.wav}")
fileArrayDrums=("${fileArray[@]/%//drums.wav}")
fileArrayBass=("${fileArray[@]/%//bass.wav}")
fileArrayPiano=("${fileArray[@]/%//piano.wav}")
fileArrayOther=("${fileArray[@]/%//other.wav}")

# list all files to be joined in a file for ffmpeg to use as input list
printf "file '%s'\n" "${fileArrayVocals[@]}" > concat-list.txt

# concatenate the parts and convert the result to $EXT
ffmpeg -f concat -safe 0 -i concat-list.txt -c copy "$NAME"/vocals.wav
ffmpeg -i "$NAME"/vocals.wav "$NAME"/vocals.$EXT

# repeat for the other stems
# drums
printf "file '%s'\n" "${fileArrayDrums[@]}" > concat-list.txt
ffmpeg -f concat -safe 0 -i concat-list.txt -c copy "$NAME"/drums.wav
ffmpeg -i "$NAME"/drums.wav "$NAME"/drums.$EXT
# bass
printf "file '%s'\n" "${fileArrayBass[@]}" > concat-list.txt
ffmpeg -f concat -safe 0 -i concat-list.txt -c copy "$NAME"/bass.wav
ffmpeg -i "$NAME"/bass.wav "$NAME"/bass.$EXT
# piano
printf "file '%s'\n" "${fileArrayPiano[@]}" > concat-list.txt
ffmpeg -f concat -safe 0 -i concat-list.txt -c copy "$NAME"/piano.wav
ffmpeg -i "$NAME"/piano.wav "$NAME"/piano.$EXT
# other
printf "file '%s'\n" "${fileArrayOther[@]}" > concat-list.txt
ffmpeg -f concat -safe 0 -i concat-list.txt -c copy "$NAME"/other.wav
ffmpeg -i "$NAME"/other.wav "$NAME"/other.$EXT

# clean up
rm "$NAME"/vocals.wav
rm "$NAME"/drums.wav
rm "$NAME"/bass.wav
rm "$NAME"/piano.wav
rm "$NAME"/other.wav
rm concat-list.txt
OLDIFS=$IFS
IFS=$'\n'
rm -r $(printf "%s\n" "${fileArray[@]}")
IFS=$OLDIFS

# clean up
rm "$NAME"-*

# deactivate (mini)conda
# conda deactivate
