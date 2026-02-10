#!/usr/bin/env bash
# Called by LaTeX Workshop: build.sh <app-dir> <workspace-root>
APP_DIR="$1"
WORKSPACE="$2"
ID=$(basename "$APP_DIR")
exec make -C "$WORKSPACE" app ID="$ID"
