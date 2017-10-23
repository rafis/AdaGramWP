#!/bin/bash
ADAGRAMWP_PATH="$HOME/.julia/v0.6/AdaGramWP/"

"$ADAGRAMWP_PATH/run.sh" "$ADAGRAMWP_PATH/utils/dictionary_MST.jl" "$@"
