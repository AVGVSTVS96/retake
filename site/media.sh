#!/usr/bin/env bash
# Rebuilds site/public/media from the app repo's real screenshots and motion captures.
set -euo pipefail
cd "$(dirname "$0")"
raw=${RETAKE:-$HOME/Developer/voice-memos}/shots
out=public/media
mkdir -p "$out"

phone() { magick "$raw/raw/$1.png" -resize "$2x" -quality 82 "$out/$1.webp"; }

for s in list-light list-dark recording-light recording-dark recording-full-light recording-full-dark \
  paused-light expanded-light expanded-dark trim-light trim-dark transcript-light options-light options-dark \
  player-light player-dark folders-light; do
  phone "iphone-18-pro-max-$s" 720
done
for s in list-light list-dark; do
  phone "ipad-pro-13-$s" 1200
  phone "iphone-duo-1-$s" 640 2>/dev/null || true
done
for s in open-list-light open-list-dark open-player-light open-player-dark; do
  phone "iphone-duo-2-$s" 1600
done

clip() {
  ffmpeg -v error -y -ss "$2" -to "$3" -i "$raw/motion/testRecordStopRecordAgain.mov" -an \
    -vf "fps=30,scale=$4:-2" -c:v libx264 -profile:v high -pix_fmt yuv420p -crf "$5" -movflags +faststart "$1"
}
clip "$out/take.mp4" 29.4 53.4 720 28
ffmpeg -v error -y -ss 29.4 -i "$raw/motion/testRecordStopRecordAgain.mov" -frames:v 1 -vf scale=720:-2 -quality 82 "$out/take-poster.webp"

logo=../brand/logo
cp $logo/favicon.svg $logo/favicon-32.png $logo/apple-touch-icon.png $logo/icon-512.png public/
