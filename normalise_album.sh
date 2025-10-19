#!/bin/bash

DIR="$1"
EXT="$2"
tracks=($(ls "$DIR"/*."$EXT" | sort -V))
#
# First remove all headroom, then enlist loudnesses and extract lowest loudness value
cd "$DIR"
for track in "${tracks[@]}"; do
    ffmpeg-normalize "$track" -nt peak -t 0 --keep-loudness-range-target \
        -tp 0 -c:a pcm_s24le -ar 48000 -ofmt wav -ext wav -p
done

# now use the output directory to find the lowest loudness and normalise all to that level
DIR=$OUTDIR
tracks=($(ls "$DIR"/*."$EXT" | sort -V))

loudnesses=()
for track in "${tracks[@]}"; do
    loudnesses+=("$(ffmpeg-normalize "$DIR"/"$track" -n -p | jq '.[0].ebu_pass1.input_i')")
done
echo "${loudnesses[@]}"



