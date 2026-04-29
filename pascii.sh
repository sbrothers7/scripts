#!/bin/bash
export PATH=$PATH:/usr/local/bin:/opt/homebrew/bin  # Homebrew paths

DEFAULT_DIR="$HOME/OBS"
EXTENSIONS='\.(mp4|mkv|webm|avi|mov)$'

generate_thumbnail() {
    local video_file="$1"
    local thumbnail
    thumbnail=$(mktemp -t fzfthumb-XXXXXX).png
    ffmpegthumbnailer -i "$video_file" -o "$thumbnail" -s 256 -f >/dev/null 2>&1
    echo "$thumbnail"
}

pick_video() {
    local start_dir="${1:-$DEFAULT_DIR}"
    local video

    video=$(
        find "$start_dir" -type f \
        | grep -Ei "$EXTENSIONS" \
        | fzf \
            --preview-window=right:70%:wrap \
            --preview '
                tmp=$(mktemp -t vidthumb-XXXXXX).png

                # Generate thumbnail
                if ffmpegthumbnailer -i {} -o "$tmp" -s 0 -f >/dev/null 2>&1; then
                    # Terminal size (in character cells)
                    cols=$(tput cols)
                    rows=$(tput lines)

                    # Preview is right:70% of the screen
                    preview_cols=$(( cols * 70 / 100 ))
                    preview_x=$(( cols - preview_cols + 1 ))   # 1-based column of preview start

                    # Choose image size in cells
                    img_w=90
                    img_h=30

                    # Center image within preview area
                    offset_x=$(( preview_x + (preview_cols - img_w) / 2 ))
                    offset_y=$(( (rows - img_h) / 2 ))

                    # Clamp offsets to be safe
                    if [ "$offset_x" -lt 1 ]; then
                        offset_x=1
                    fi
                    if [ "$offset_y" -lt 1 ]; then
                        offset_y=1
                    fi

                    kitty +kitten icat \
                        --transfer-mode=file \
                        --stdin=no \
                        --silent \
                        --clear \
                        --place "${img_w}x${img_h}@${offset_x}x${offset_y}" \
                        "$tmp" < /dev/null > /dev/tty 2>/dev/null
                else
                    echo "Thumbnail not available"
                    echo "{}"
                fi

                rm -f "$tmp"
            ' \
            --prompt="Pick a video: "
    )

    echo "$video"
}

if [ $# -eq 0 ]; then
    VIDEO=$(pick_video "$DEFAULT_DIR")
else
    VIDEO="$1"
fi

if [ -z "$VIDEO" ]; then
    echo "No video selected. Exiting..."
    exit 1
fi

echo "Playing: $VIDEO"
mpv --vo=tct "$VIDEO"
