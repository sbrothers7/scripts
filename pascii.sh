#!/bin/bash
export PATH=$PATH:/usr/local/bin:/opt/homebrew/bin  # Add directories where Homebrew installs binaries

# Where to start browsing from by default
DEFAULT_DIR="$HOME/Desktop"

# Supported video extensions
EXTENSIONS='\.(mp4|mkv|webm|avi|mov)$'

# Function to generate a temporary thumbnail using ffmpegthumbnailer
generate_thumbnail() {
  local video_file="$1"
  local thumbnail=$(mktemp).png
  ffmpegthumbnailer -i "$video_file" -o "$thumbnail" -s 0
  echo "$thumbnail"
}

# Function: interactive picker using tree + fzf
pick_video() {
  local start_dir="${1:-$DEFAULT_DIR}"
  local video

  video=$(
    find "$start_dir" -type f \
      | grep -Ei "$EXTENSIONS" \
      | fzf \
        --preview-window=up:30%:wrap \
        --preview '
          # 1) make a tmp name (macOS mktemp -t prefix)
          tmp=$(mktemp -t fzfthumb)
          thumb="${tmp}.png"

          # 2) drop the zero-byte file so we can write thumb.png
          rm -f "$tmp"

          # 3) generate your thumbnail
          ffmpegthumbnailer -i {} -s 256 -o "$thumb" -f 2>/dev/null

          # 4) only if it actually exists, pass it to kitty
          if [[ -f "$thumb" ]]; then
            kitty +kitten icat \
              --transfer-mode file \
              --silent \
              --clear \
              "$thumb"
          fi

          # 5) finally, clean up
          rm -f "$thumb"
        ' \
        --prompt="🎥 Pick a video: "
  )

  echo "$video"
}

# Main logic
if [ $# -eq 0 ]; then
  VIDEO=$(pick_video "$DEFAULT_DIR")
else
  VIDEO="$1"
fi

# Exit if nothing selected
if [ -z "$VIDEO" ]; then
  echo "❌ No video selected. Exiting."
  exit 1
fi

# Confirm and play using Kitty's ASCII renderer
echo "▶️  Playing: $VIDEO"
mpv --vo=tct "$VIDEO"

