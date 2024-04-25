#!/usr/bin/env bash

SRCROOT=$(pwd)
export SRCROOT

set -euo pipefail

excluded_frameworks=("Pods_DummyApp" "DummyApp")

function unzip_archives() {
  PLATFORM="$1"

  mkdir -p ./build/"$PLATFORM"

  tar zxvf "./$PLATFORM-binary.tar.gz" --directory ./build/"$PLATFORM"
}

function create_xcframework() {
  rm -rf $SRCROOT/Frameworks
  mkdir $SRCROOT/Frameworks

  # Find frameworks
  for framework in $(find ./build/iphoneos/ -type d -name "*.framework"); do
    basename=$(basename $framework)
    framework_name=$(basename $framework .framework)

    echo "Processing $framework_name"

    if [[ " ${excluded_frameworks[*]} " =~ " ${framework_name} " ]]; then
      continue
    fi

    xcodebuild -create-xcframework \
      -framework ./build/iphonesimulator/$basename \
      -framework ./build/iphoneos/$basename \
      -output $SRCROOT/Frameworks/$framework_name.xcframework

    echo "Created xcframework: $framework_name.xcframework"
  done

  cp LICENSE Frameworks/
  # tar -cvzf HyperswitchSDK.tar.gz Frameworks
}

cd $SRCROOT
unzip_archives iphoneos
unzip_archives iphonesimulator
create_xcframework
