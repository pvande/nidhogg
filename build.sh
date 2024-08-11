#!/bin/sh

OSTYPE=`uname -s`
if [ "$OSTYPE" = "Darwin" ]; then
  PLATFORM=macos
  DLLEXT=dylib
else
  exit
fi

mkdir -p whim/native/$PLATFORM

clang -isystem whim/include -arch x86_64 -arch arm64 -shared -framework Foundation -o whim/native/$PLATFORM/menufix.$DLLEXT whim/native/menufix.c
