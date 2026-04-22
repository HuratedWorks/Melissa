#!/usr/bin/env bash

set -euo pipefail

script_name="$(basename "$0")"
script_base="${script_name%.sh}"

default_source='melissa-??.md'
default_output='melissa-all.md'
default_separator='\n***\n'

sources=("$default_source")
source_files=()
use_default_sources=true
output_file="$default_output"
separator_raw="$default_separator"
assume_yes=false
command=""

print_help() {
  cat <<EOF
Usage:
  ./${script_name} all [options]

Description:
  "${script_base} all" joins chapter files into one Markdown file.

Commands:
  all                       Join the selected source files into one file.

Options:
  -s, --source VALUE        Source file path or shell glob. Repeatable.
                            Default: ${default_source}
  -o, --output FILE         Destination file name.
                            Default: ${default_output}
  -p, --separator TEXT      Separator inserted between chapters.
                            C-style escapes are interpreted.
                            Default: '${default_separator}'
  -y, --yes                 Overwrite destination without asking.
  -h, --help                Show this help.

Examples:
  ./${script_name} all
  ./${script_name} all -o book.md
  ./${script_name} all -s 'melissa-0[1-4].md' -s epilogue.md
  ./${script_name} all -p '\n---\n'
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

normalize_path() {
  local value="$1"
  value="${value#./}"
  printf '%s' "$value"
}

contains_path() {
  local needle="$1"
  shift || true
  local item

  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done

  return 1
}

collect_sources() {
  local spec match
  local -a matches=()

  source_files=()

  for spec in "${sources[@]}"; do
    matches=()

    if [[ -e "$spec" ]]; then
      matches=("$spec")
    else
      while IFS= read -r match; do
        matches+=("$match")
      done < <(compgen -G "$spec" | LC_ALL=C sort)
    fi

    if ((${#matches[@]} == 0)); then
      die "source '${spec}' did not match any files"
    fi

    for match in "${matches[@]}"; do
      if [[ ! -f "$match" ]]; then
        die "source '${match}' is not a regular file"
      fi

      match="$(normalize_path "$match")"

      if contains_path "$match" "${source_files[@]}"; then
        continue
      fi

      source_files+=("$match")
    done
  done
}

render_output() {
  local destination="$1"
  local separator="$2"
  shift 2
  local -a files=("$@")
  local first=true

  : > "$destination"

  for file in "${files[@]}"; do
    if [[ "$first" == true ]]; then
      first=false
    else
      printf '%s' "$separator" >> "$destination"
    fi

    cat -- "$file" >> "$destination"
  done
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
    all)
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
    -p|--separator)
      (($# >= 2)) || die "missing value for $1"
      separator_raw="$2"
      shift 2
      ;;
    --separator=*)
      separator_raw="${1#*=}"
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

if [[ "$command" != "all" ]]; then
  die "unsupported command '${command}'"
fi

separator_value="$(printf '%b' "$separator_raw")"
output_norm="$(normalize_path "$output_file")"

collect_sources

if ((${#source_files[@]} == 0)); then
  die "no source files collected"
fi

for file in "${source_files[@]}"; do
  if [[ "$(normalize_path "$file")" == "$output_norm" ]]; then
    die "destination '${output_file}' must not also be a source file"
  fi
done

tmp_file="$(mktemp "${TMPDIR:-/tmp}/${script_base}-chapters.XXXXXX")"
cleanup() {
  rm -f -- "$tmp_file"
}
trap cleanup EXIT

render_output "$tmp_file" "$separator_value" "${source_files[@]}"

new_bytes="$(wc -c < "$tmp_file" | tr -d '[:space:]')"
new_lines="$(wc -l < "$tmp_file" | tr -d '[:space:]')"

if [[ -e "$output_file" && "$assume_yes" != true ]]; then
  existing_bytes="$(wc -c < "$output_file" | tr -d '[:space:]')"
  existing_lines="$(wc -l < "$output_file" | tr -d '[:space:]')"

  printf "Destination '%s' already exists.\n" "$output_file"
  printf '  Existing file: %s bytes, %s lines\n' "$existing_bytes" "$existing_lines"
  printf '  New combined file: %s bytes, %s lines\n' "$new_bytes" "$new_lines"
  printf 'Proceed and overwrite? [y/N] '

  read -r reply
  case "$reply" in
    y|Y|yes|YES|Yes)
      ;;
    *)
      printf 'Aborted.\n'
      exit 0
      ;;
  esac
fi

mv -f -- "$tmp_file" "$output_file"
trap - EXIT

printf "Wrote %s chapter(s) to '%s' (%s bytes, %s lines).\n" \
  "${#source_files[@]}" \
  "$output_file" \
  "$new_bytes" \
  "$new_lines"
