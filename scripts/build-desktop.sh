#!/bin/bash
flutter clean
mkdir -p ../artifacts
formats=("linux-appimage" "linux-deb" "linux-rpm" "windows-msi" "darwin-pkg" "darwin-dmg")
for format in "${formats[@]}"; do
  rm -rf go/build
  hover build "$format" "$@"
  status=$?
  if [[ "$status" != 0 ]]; then
    exit 1
  fi
  cp go/build/outputs/"$format"/* ../artifacts/
done
cd ..