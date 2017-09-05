#!/bin/bash
ADAGRAM_PATH="$HOME/.julia/v0.6/AdaGram"

"$ADAGRAM_PATH/run.sh" "$ADAGRAM_PATH/utils/dictionary_MST.jl" "$@"
