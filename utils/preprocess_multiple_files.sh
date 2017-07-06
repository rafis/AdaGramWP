#!/bin/bash

find . -type f -exec cat {} + >> allfiles.txt
/home/andres/.julia/v0.4/AdaGram/utils/tokenize_leaveCaps.sh allfiles.txt tokenized_allfiles.txt
/home/andres/.julia/v0.4/AdaGram/utils/dictionary.sh tokenized_allfiles.txt dict_allfiles.txt