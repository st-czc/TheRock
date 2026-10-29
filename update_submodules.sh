#!/bin/bash
# Initialize and update the submodules used by the HIP CPU build.

set -euo pipefail

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SUBMODULES=(
  rocm-cmake
  llvm-project
  hipcpu-passes
  llvm-project-hipcpu
  spirv-llvm-translator
  rocm-systems
  rocm-libraries
)

update_submodule() {
  local name="$1" path url branch gitlink subdir

  path="$(git config -f "$THIS_DIR/.gitmodules" --get "submodule.${name}.path")"
  url="$(git config -f "$THIS_DIR/.gitmodules" --get "submodule.${name}.url")"
  branch="$(git config -f "$THIS_DIR/.gitmodules" --get "submodule.${name}.branch" 2>/dev/null || true)"
  gitlink="$(git -C "$THIS_DIR" rev-parse ":${path}")"
  subdir="$THIS_DIR/$path"

  git -C "$THIS_DIR" submodule init -- "$path"

  if [ ! -e "$subdir/.git" ]; then
    git init -q "$subdir"
    git -C "$subdir" remote add origin "$url"
    git -C "$subdir" fetch --depth 1 origin "$gitlink"
    if [ -n "$branch" ]; then
      git -C "$subdir" remote set-branches origin "$branch"
    fi
  fi

  git -C "$subdir" fetch origin "$gitlink"
  if [ -n "$branch" ]; then
    git -C "$subdir" fetch origin "$branch"
  fi

  git -C "$subdir" checkout -q --detach "$gitlink"

  git -C "$THIS_DIR" submodule absorbgitdirs -- "$path"
}

for name in "${SUBMODULES[@]}"; do
  update_submodule "$name"
done
