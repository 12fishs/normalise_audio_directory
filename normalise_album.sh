#!/bin/bash

DIR="$1"
HEADROOM="$2"

tracks=()
while IFS= read -r -d '' file; do
    tracks+=("$file")
done < <(find "$DIR" -type f -iname "*.wav" -print0 | sort -z -V)

peak_0_loudnesses=()
echo "analysing:"
for track in "${tracks[@]}"; do
    echo "$track"
    data=$(ffmpeg-normalize "$track" -n -p -q)
    peak_0_loudnesses+=("$(jq '.[0].ebu_pass1.input_i - .[0].ebu_pass1.input_tp' <<< "$data")")
done
# find minimum
desired_loudness=${peak_0_loudnesses[0]}
for i in "${peak_0_loudnesses[@]}"; do
    if [ "$(bc -l <<< "$i < $desired_loudness")" -eq 1 ]; then
        desired_loudness=$i
    fi 
done
desired_loudness=$(echo "$desired_loudness - $HEADROOM" | bc -l)
echo "desired loudness: $desired_loudness"

for track in "${tracks[@]}"; do
    sample_rate=$(mdls -name kMDItemAudioSampleRate "$track" | awk '{print $3}')
    echo "normalising $track"
    ffmpeg-normalize "$track" -t "$desired_loudness" --keep-loudness-range-target -tp 0 \
        --auto-lower-loudness-target -ar "$sample_rate" -ofmt wav -ext wav
done
