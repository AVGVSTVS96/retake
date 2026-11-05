#!/usr/bin/env bash
# Re-renders every image asset from its HTML source, one at a time.
set -euo pipefail
cd "$(dirname "$0")"
export TMPDIR=${TMPDIR:-$PWD/../.scratch}
mkdir -p "$TMPDIR"
shoot="bun $HOME/.agents/skills/brand-it/scripts/shoot.mjs"
bun logo/gen.mjs
cd assets
$shoot og.html 1200x630 og.png
$shoot github.html 1280x640 github.png
$shoot readme-light.html 838x300@2 readme-light.png --clear
$shoot readme-dark.html 838x300@2 readme-dark.png --clear
for f in x-1-light-dark x-2-stop x-3-devices x-4-300 x-5-quote; do $shoot $f.html 1600x900 $f.png; done
cp og.png ../../site/public/og.png
