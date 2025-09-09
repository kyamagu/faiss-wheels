#!/usr/bin/env bash

set -eux

# Install system dependencies.
brew install libomp

# Set MACOSX_DEPLOYMENT_TARGET.
# NOTE: This is a workaround for the compatibility with libomp on Homebrew.
# For C++17 compatibility, the minimum required version is 10.13.
# Perhaps a workaround is to build libomp here from LLVM project.
MACOS_VERSION=$(sw_vers -productVersion)
if [[ "$MACOS_VERSION" =~ ^13\. ]]; then
    echo "MACOSX_DEPLOYMENT_TARGET=13.0" >> $GITHUB_ENV
else
    echo "MACOSX_DEPLOYMENT_TARGET=14.0" >> $GITHUB_ENV
fi
