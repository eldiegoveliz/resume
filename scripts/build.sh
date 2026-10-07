#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 1 && $1 == --help ]]; then
  cat <<'HELP'
Usage: ./scripts/build.sh

Rebuild resume.md, resume.pdf, Diego Véliz.pdf, and diego-veliz.pdf
from resume.tex. Requires pandoc, pdfinfo, and a LaTeX compiler:
latexmk, pdflatex, or tectonic.

Set RESUME_COMPILER to select a compiler or its full path.
Generated files are published only after compilation and conversion succeed.
HELP
  exit 0
fi
if [[ $# -ne 0 ]]; then
  echo 'Usage: ./scripts/build.sh [--help]' >&2
  exit 2
fi

cd "$(dirname "${BASH_SOURCE[0]}")/.."
for tool in pandoc pdfinfo; do
  command -v "$tool" >/dev/null || { echo "Missing dependency: $tool" >&2; exit 1; }
done

compiler=${RESUME_COMPILER:-}
if [[ -z $compiler ]]; then
  for candidate in latexmk pdflatex tectonic; do
    if command -v "$candidate" >/dev/null; then
      compiler=$candidate
      break
    fi
  done
fi
if [[ -z $compiler ]]; then
  echo 'Install latexmk, pdflatex, or tectonic to rebuild the PDF.' >&2
  exit 1
fi

mkdir -p .build
build_dir=$(mktemp -d "$PWD/.build/run.XXXXXX")
trap 'rm -rf -- "$build_dir"' EXIT

case ${compiler##*/} in
  latexmk)
    "$compiler" -pdf -interaction=nonstopmode -halt-on-error -file-line-error \
      -outdir="$build_dir" resume.tex
    ;;
  pdflatex)
    for pass in 1 2; do
      "$compiler" -interaction=nonstopmode -halt-on-error -file-line-error \
        -output-directory="$build_dir" resume.tex
    done
    ;;
  tectonic)
    "$compiler" --outdir "$build_dir" resume.tex
    ;;
  *)
    echo "Unsupported compiler: $compiler" >&2
    exit 1
    ;;
esac

pandoc resume.tex --from=latex --to=gfm --wrap=none \
  --lua-filter=scripts/markdown.lua --output="$build_dir/resume.md"
pdfinfo "$build_dir/resume.pdf" >/dev/null

for name in resume.pdf 'Diego Véliz.pdf' diego-veliz.pdf; do
  cp -- "$build_dir/resume.pdf" "$build_dir/$name.publish"
  mv -- "$build_dir/$name.publish" "$name"
done
mv -- "$build_dir/resume.md" resume.md
echo 'Built resume.md and all three PDF filenames.'
