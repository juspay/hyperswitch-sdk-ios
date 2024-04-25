#!/usr/bin/env bash

SRCROOT=$(pwd)
export SRCROOT

PLATFORM=$1

OUT="$PLATFORM-binary.tar.gz"
set -euo pipefail

echo $(pwd)

function archive() {
  SDK=$PLATFORM
  DESTINATION=""

  architectures="\"arm64 x86_64\""
  if [ "$PLATFORM" == "iphoneos" ]; then
    architectures="arm64"
  fi

  XCODEBUILD_COMMAND="xcodebuild archive \
    -workspace "DummyApp.xcworkspace" \
    -scheme DummyApp \
    -configuration Release \
    -archivePath $SRCROOT/DummyApp-$PLATFORM.xcarchive \
    -sdk $SDK \
    $DESTINATION \
    ENABLE_BITCODE=NO \
    SKIP_INSTALL=NO \
    ARCHS=$architectures \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    SUPPORTS_MACCATALYST=NO | xcbeautify"

  eval $XCODEBUILD_COMMAND
}

archive

OUT=$(pwd)/$OUT
pushd "$SRCROOT/DummyApp-$PLATFORM.xcarchive/Products/Library/Frameworks" || exit 1
tar -cvf "$OUT" ./*
popd || exit 1
