#!/usr/bin/env bash

SRCROOT=$(pwd)
export SRCROOT

set -euo pipefail

excluded_frameworks=("Pods_DummyApp" "DummyApp", "react-native-hyperswitch-netcetera-3ds")
sentry_frameworks=("Sentry" "SentryPrivate" "RNSentry")
scancard_frameworks=("react_native_hyperswitch_scancard")

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

    if [[ " ${sentry_frameworks[*]} " =~ " ${framework_name} " ]]; then
      xcodebuild -create-xcframework \
      -framework ./build/iphonesimulator/$basename \
      -framework ./build/iphoneos/$basename \
      -output $SRCROOT/Frameworks/Sentry/$framework_name.xcframework

    elif [[ " ${scancard_frameworks[*]} " =~ " ${framework_name} " ]]; then
      xcodebuild -create-xcframework \
      -framework ./build/iphonesimulator/$basename \
      -framework ./build/iphoneos/$basename \
      -output $SRCROOT/Frameworks/ScanCard/$framework_name.xcframework

    else
      xcodebuild -create-xcframework \
        -framework ./build/iphonesimulator/$basename \
        -framework ./build/iphoneos/$basename \
        -output $SRCROOT/Frameworks/Core/$framework_name.xcframework
    fi

    echo "Created xcframework: $framework_name.xcframework"
  done

  cp LICENSE Frameworks/
  # tar -cvzf HyperswitchSDK.tar.gz Frameworks
}

cd $SRCROOT
unzip_archives iphoneos
unzip_archives iphonesimulator
create_xcframework
