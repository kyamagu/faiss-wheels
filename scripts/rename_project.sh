#!/usr/bin/env bash

set -eux

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS/BSD sed requires an argument for -i (can be empty)
  sed -i '' "s/^name = \"faiss-cpu\"/name = \"${1}\"/" pyproject.toml
else
  # GNU sed (Linux) works with just -i
  sed -i "s/^name = \"faiss-cpu\"/name = \"${1}\"/" pyproject.toml
fi