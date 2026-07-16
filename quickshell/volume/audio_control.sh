#!/usr/bin/env bash
set -eu

ACTION=${1:-}
TYPE=${2:-}
ID=${3:-}
VAL=${4:-}

case "$TYPE" in
    sink|source) ;;
    *) printf 'invalid type: %s\n' "$TYPE" >&2; exit 64 ;;
esac

case "$ACTION" in
    set-volume)
        if [[ "$ID" == "@DEFAULT@" ]]; then
            if [[ "$TYPE" == "sink" ]]; then
                wpctl set-volume @DEFAULT_AUDIO_SINK@ "$VAL%"
            elif [[ "$TYPE" == "source" ]]; then
                wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "$VAL%"
            fi
        else
            pactl "set-${TYPE}-volume" "$ID" "$VAL%"
        fi
        ;;
    toggle-mute)
        if [[ "$ID" == "@DEFAULT@" ]]; then
            if [[ "$TYPE" == "sink" ]]; then
                wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
            elif [[ "$TYPE" == "source" ]]; then
                wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
            fi
        else
            pactl "set-${TYPE}-mute" "$ID" toggle
        fi
        ;;
    set-default)
        pactl "set-default-${TYPE}" "$ID"
        ;;
esac
