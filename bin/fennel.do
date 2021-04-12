#!/bin/bash

FENNEL_VERSION="0.9.0"

wget "https://fennel-lang.org/downloads/fennel-$FENNEL_VERSION" --output-document="$3"
chmod u+x "$3"
