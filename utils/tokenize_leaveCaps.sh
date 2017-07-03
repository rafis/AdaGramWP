#!/bin/bash

tr '[:punct:]' ' ' < $1 | tr '[:space:]' ' ' | tr -cd '[:alnum:] ' | tr -s ' ' > $2
