#!/bin/sh
printf '\033c\033]0;%s\a' school21_game
base_path="$(dirname "$(realpath "$0")")"
"$base_path/school21_game_v1.x86_64" "$@"
