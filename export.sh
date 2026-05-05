#!/usr/bin/env bash

set -euo pipefail

script_name="$(basename "$0")"
script_base="${script_name%.sh}"

default_sources=("melissa-all.md" "melissa-all-illustrated.md")
sources=("${default_sources[@]}")
use_default_sources=true
output_file=""
assume_yes=false
command=""
chrome_bin="${PDF_CHROME:-}"
css_file=""
paper_size="Letter"
compress_mode="auto"

print_help() {
  cat <<EOF
Usage:
  ./${script_name} pdf [options]

Description:
  "${script_base} pdf" converts Markdown files to PDF.

Commands:
  pdf                       Convert selected Markdown file(s) to PDF.

Options:
  -s, --source FILE         Source Markdown file. Repeatable.
                            Default: ${default_sources[*]}
  -o, --output FILE         Destination PDF file.
                            Allowed only when one source is selected.
                            Default: source file name with .pdf extension.
  --chrome PATH             Chrome/Chromium executable path.
                            Default: auto-detect, or PDF_CHROME if set.
  --css FILE                Additional CSS appended to the built-in print CSS.
                            Default: none
  --paper-size VALUE        CSS page size.
                            Default: ${paper_size}
  --compress                Compress PDF with Ghostscript.
                            Requires gs.
  --no-compress             Do not compress PDF.
                            Default: auto-compress illustrated PDFs if gs exists.
  -y, --yes                 Overwrite destination without asking.
  -h, --help                Show this help.

Required tools:
  Markdown renderer: markdown-it, pandoc, cmark, multimarkdown, or lowdown.
  PDF renderer: Google Chrome or Chromium.

Install examples:
  macOS:
    brew install node
    npm install -g markdown-it
    brew install --cask google-chrome
    brew install ghostscript        # optional, for compression

  Debian/Ubuntu:
    sudo apt install nodejs npm chromium ghostscript
    sudo npm install -g markdown-it

Examples:
  ./${script_name} pdf
  ./${script_name} pdf -y
  ./${script_name} pdf -s melissa-all.md
  ./${script_name} pdf -s melissa-all.md -o draft.pdf --paper-size A4
  PDF_CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ./${script_name} pdf
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

warn() {
  printf 'Warning: %s\n' "$*" >&2
}

normalize_path() {
  local value="$1"
  value="${value#./}"
  printf '%s' "$value"
}

absolute_path() {
  local path="$1"
  local dir base
  dir="$(dirname "$path")"
  base="$(basename "$path")"

  (
    cd "$dir"
    printf '%s/%s' "$(pwd -P)" "$base"
  )
}

absolute_dir() {
  local dir="$1"

  (
    cd "$dir"
    pwd -P
  )
}

bytes_for() {
  wc -c < "$1" | tr -d '[:space:]'
}

pages_for() {
  if command -v pdfinfo >/dev/null 2>&1; then
    pdfinfo "$1" 2>/dev/null | awk '/^Pages:/ {print $2; found=1} END {if (!found) print "unknown"}'
  else
    printf 'unknown'
  fi
}

print_missing_renderer_help() {
  cat >&2 <<EOF
No Markdown renderer was found.

Install one of these tools:
  macOS:
    brew install node
    npm install -g markdown-it
    # or: brew install pandoc

  Debian/Ubuntu:
    sudo apt install nodejs npm
    sudo npm install -g markdown-it
    # or: sudo apt install pandoc

  Fedora:
    sudo dnf install nodejs npm pandoc
    sudo npm install -g markdown-it
EOF
}

print_missing_browser_help() {
  cat >&2 <<EOF
No Chrome/Chromium executable was found.

Install Chrome or Chromium:
  macOS:
    brew install --cask google-chrome

  Debian/Ubuntu:
    sudo apt install chromium
    # or install Google Chrome from the official .deb package

  Fedora:
    sudo dnf install chromium

If Chrome is installed in a custom location, pass:
  ./${script_name} pdf --chrome /path/to/chrome
or set:
  PDF_CHROME=/path/to/chrome
EOF
}

print_missing_gs_help() {
  cat >&2 <<EOF
Ghostscript is required for PDF compression.

Install it with:
  macOS:
    brew install ghostscript

  Debian/Ubuntu:
    sudo apt install ghostscript

  Fedora:
    sudo dnf install ghostscript

Or rerun with --no-compress.
EOF
}

find_markdown_renderer() {
  if command -v markdown-it >/dev/null 2>&1; then
    printf 'markdown-it:%s' "$(command -v markdown-it)"
  elif command -v pandoc >/dev/null 2>&1; then
    printf 'pandoc:%s' "$(command -v pandoc)"
  elif command -v cmark >/dev/null 2>&1; then
    printf 'cmark:%s' "$(command -v cmark)"
  elif command -v multimarkdown >/dev/null 2>&1; then
    printf 'multimarkdown:%s' "$(command -v multimarkdown)"
  elif command -v lowdown >/dev/null 2>&1; then
    printf 'lowdown:%s' "$(command -v lowdown)"
  else
    return 1
  fi
}

find_browser() {
  local candidate

  if [[ -n "$chrome_bin" ]]; then
    if [[ -x "$chrome_bin" ]]; then
      printf '%s' "$chrome_bin"
      return 0
    fi
    die "Chrome executable '${chrome_bin}' is not executable"
  fi

  for candidate in \
    google-chrome \
    google-chrome-stable \
    chromium \
    chromium-browser \
    chrome \
    microsoft-edge \
    msedge \
    brave-browser
  do
    if command -v "$candidate" >/dev/null 2>&1; then
      command -v "$candidate"
      return 0
    fi
  done

  for candidate in \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Chromium.app/Contents/MacOS/Chromium" \
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
    "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
  do
    if [[ -x "$candidate" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
  done

  return 1
}

render_markdown_body() {
  local renderer="$1"
  local source="$2"
  local renderer_name renderer_path

  renderer_name="${renderer%%:*}"
  renderer_path="${renderer#*:}"

  case "$renderer_name" in
    markdown-it)
      "$renderer_path" "$source"
      ;;
    pandoc)
      "$renderer_path" -f markdown -t html "$source"
      ;;
    cmark)
      "$renderer_path" --unsafe "$source"
      ;;
    multimarkdown)
      "$renderer_path" "$source"
      ;;
    lowdown)
      "$renderer_path" -T html "$source"
      ;;
    *)
      die "unsupported Markdown renderer '${renderer_name}'"
      ;;
  esac
}

html_escape() {
  sed \
    -e 's/&/\&amp;/g' \
    -e 's/</\&lt;/g' \
    -e 's/>/\&gt;/g'
}

build_html() {
  local source="$1"
  local html_file="$2"
  local renderer="$3"
  local source_base_dir

  source_base_dir="$(absolute_dir "$(dirname "$source")")"

  {
    printf '%s\n' '<!doctype html>'
    printf '%s\n' '<html>'
    printf '%s\n' '<head>'
    printf '%s\n' '<meta charset="utf-8">'
    printf '<base href="file://'
    printf '%s' "$source_base_dir" | html_escape
    printf '%s\n' '/">'
    printf '<title>'
    printf '%s' "$(basename "$source")" | html_escape
    printf '%s\n' '</title>'
    printf '%s\n' '<style>'
    printf '@page { size: %s; margin: 22mm 18mm; }\n' "$paper_size"
    printf '%s\n' 'body { font-family: "Liberation Serif", Georgia, serif; font-size: 13pt; line-height: 1.42; color: #111; }'
    printf '%s\n' 'h1, h2, h3 { line-height: 1.2; }'
    printf '%s\n' 'h3 { font-size: 21pt; margin: 0 0 18px; break-before: page; page-break-before: always; }'
    printf '%s\n' 'h3:first-of-type { break-before: auto; page-break-before: auto; }'
    printf '%s\n' 'p { margin: 0 0 0.7em; }'
    printf '%s\n' 'img { display: block; max-width: 92%; max-height: 210mm; margin: 0 auto 18px; }'
    printf '%s\n' 'hr { margin: 18px 0; border: 0; border-top: 1px solid #888; }'
    printf '%s\n' 'div[style*="page-break-after"] { break-after: page; page-break-after: always; }'
    printf '%s\n' 'code { font-family: "Liberation Mono", monospace; font-size: 0.9em; }'
    if [[ -n "$css_file" ]]; then
      printf '\n/* Additional CSS: %s */\n' "$css_file"
      cat -- "$css_file"
      printf '\n'
    fi
    printf '%s\n' '</style>'
    printf '%s\n' '</head>'
    printf '%s\n' '<body>'
    render_markdown_body "$renderer" "$source"
    printf '%s\n' '</body>'
    printf '%s\n' '</html>'
  } > "$html_file"
}

derive_output_path() {
  local source="$1"

  case "$source" in
    *.md)
      printf '%s.pdf' "${source%.*}"
      ;;
    *)
      printf '%s.pdf' "$source"
      ;;
  esac
}

make_temp_dir_near() {
  local path="$1"
  local dir
  dir="$(dirname "$path")"
  mktemp -d "${dir}/.${script_base}.XXXXXX"
}

should_compress() {
  local output="$1"

  case "$compress_mode" in
    always)
      return 0
      ;;
    never)
      return 1
      ;;
    auto)
      case "$(basename "$output")" in
        *illustrated*.pdf)
          return 0
          ;;
        *)
          return 1
          ;;
      esac
      ;;
    *)
      die "invalid compression mode '${compress_mode}'"
      ;;
  esac
}

compress_pdf() {
  local pdf_file="$1"
  local compressed_file
  local original_bytes compressed_bytes

  if ! command -v gs >/dev/null 2>&1; then
    if [[ "$compress_mode" == "auto" ]]; then
      warn "Ghostscript not found; leaving '$(basename "$pdf_file")' uncompressed. Use --no-compress to silence this warning."
      return 0
    fi
    print_missing_gs_help
    exit 1
  fi

  compressed_file="${pdf_file}.compressed"
  gs \
    -sDEVICE=pdfwrite \
    -dCompatibilityLevel=1.4 \
    -dPDFSETTINGS=/ebook \
    -dNOPAUSE \
    -dQUIET \
    -dBATCH \
    -sOutputFile="$compressed_file" \
    "$pdf_file"

  original_bytes="$(bytes_for "$pdf_file")"
  compressed_bytes="$(bytes_for "$compressed_file")"

  if [[ -s "$compressed_file" && "$compressed_bytes" -lt "$original_bytes" ]]; then
    mv -f -- "$compressed_file" "$pdf_file"
  else
    rm -f -- "$compressed_file"
  fi
}

confirm_overwrite() {
  local output="$1"
  local new_pdf="$2"
  local existing_bytes existing_pages new_bytes new_pages reply

  if [[ ! -e "$output" || "$assume_yes" == true ]]; then
    return 0
  fi

  existing_bytes="$(bytes_for "$output")"
  existing_pages="$(pages_for "$output")"
  new_bytes="$(bytes_for "$new_pdf")"
  new_pages="$(pages_for "$new_pdf")"

  printf "Destination '%s' already exists.\n" "$output"
  printf '  Existing file: %s bytes, %s pages\n' "$existing_bytes" "$existing_pages"
  printf '  New PDF file:  %s bytes, %s pages\n' "$new_bytes" "$new_pages"
  printf 'Proceed and overwrite? [y/N] '

  read -r reply
  case "$reply" in
    y|Y|yes|YES|Yes)
      ;;
    *)
      printf 'Skipped %s.\n' "$output"
      return 1
      ;;
  esac
}

convert_one() {
  local source="$1"
  local output="$2"
  local renderer="$3"
  local browser="$4"
  local temp_dir html_file pdf_file source_dir output_dir
  local final_bytes final_pages

  [[ -f "$source" ]] || die "source '${source}' is not a regular file"

  source_dir="$(dirname "$source")"
  output_dir="$(dirname "$output")"

  [[ -d "$source_dir" ]] || die "source directory '${source_dir}' does not exist"
  [[ -d "$output_dir" ]] || die "output directory '${output_dir}' does not exist"

  if [[ "$(normalize_path "$source")" == "$(normalize_path "$output")" ]]; then
    die "source and output must be different files"
  fi

  temp_dir="$(make_temp_dir_near "$output")"
  html_file="${temp_dir}/index.html"
  pdf_file="${temp_dir}/output.pdf"

  cleanup_one() {
    rm -rf -- "$temp_dir"
  }

  build_html "$source" "$html_file" "$renderer"

  "$browser" \
    --headless \
    --disable-gpu \
    --disable-dev-shm-usage \
    --no-sandbox \
    --no-pdf-header-footer \
    --print-to-pdf="$pdf_file" \
    "file://$(absolute_path "$html_file")" >/dev/null 2>&1 || {
      cleanup_one
      die "Chrome/Chromium failed to render '${source}'"
    }

  if should_compress "$output"; then
    compress_pdf "$pdf_file"
  fi

  if confirm_overwrite "$output" "$pdf_file"; then
    mv -f -- "$pdf_file" "$output"
    final_bytes="$(bytes_for "$output")"
    final_pages="$(pages_for "$output")"
    printf "Wrote '%s' from '%s' (%s bytes, %s pages).\n" \
      "$output" \
      "$source" \
      "$final_bytes" \
      "$final_pages"
  fi

  cleanup_one
}

if (($# == 0)); then
  print_help
  exit 0
fi

while (($# > 0)); do
  case "$1" in
    -h|--help)
      print_help
      exit 0
      ;;
    pdf)
      [[ -z "$command" ]] || die "command already set to '${command}'"
      command="$1"
      shift
      ;;
    -s|--source)
      (($# >= 2)) || die "missing value for $1"
      if [[ "$use_default_sources" == true ]]; then
        sources=()
        use_default_sources=false
      fi
      sources+=("$2")
      shift 2
      ;;
    --source=*)
      if [[ "$use_default_sources" == true ]]; then
        sources=()
        use_default_sources=false
      fi
      sources+=("${1#*=}")
      shift
      ;;
    -o|--output)
      (($# >= 2)) || die "missing value for $1"
      output_file="$2"
      shift 2
      ;;
    --output=*)
      output_file="${1#*=}"
      shift
      ;;
    --chrome)
      (($# >= 2)) || die "missing value for $1"
      chrome_bin="$2"
      shift 2
      ;;
    --chrome=*)
      chrome_bin="${1#*=}"
      shift
      ;;
    --css)
      (($# >= 2)) || die "missing value for $1"
      css_file="$2"
      shift 2
      ;;
    --css=*)
      css_file="${1#*=}"
      shift
      ;;
    --paper-size)
      (($# >= 2)) || die "missing value for $1"
      paper_size="$2"
      shift 2
      ;;
    --paper-size=*)
      paper_size="${1#*=}"
      shift
      ;;
    --compress)
      compress_mode="always"
      shift
      ;;
    --no-compress)
      compress_mode="never"
      shift
      ;;
    -y|--yes)
      assume_yes=true
      shift
      ;;
    -*)
      die "unknown option '$1'"
      ;;
    *)
      die "unknown command '$1'"
      ;;
  esac
done

if [[ -z "$command" ]]; then
  print_help
  exit 0
fi

if [[ "$command" != "pdf" ]]; then
  die "unsupported command '${command}'"
fi

if ((${#sources[@]} == 0)); then
  die "no source files selected"
fi

if [[ -n "$output_file" && ${#sources[@]} -ne 1 ]]; then
  die "--output can only be used with exactly one --source"
fi

if [[ -n "$css_file" && ! -f "$css_file" ]]; then
  die "CSS file '${css_file}' does not exist"
fi

if ! renderer="$(find_markdown_renderer)"; then
  print_missing_renderer_help
  exit 1
fi

if ! browser="$(find_browser)"; then
  print_missing_browser_help
  exit 1
fi

for source in "${sources[@]}"; do
  if [[ -n "$output_file" ]]; then
    output="$output_file"
  else
    output="$(derive_output_path "$source")"
  fi

  convert_one "$source" "$output" "$renderer" "$browser"
done
