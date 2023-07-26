#!/bin/bash

#
# Usage: this-run --label
# Option: change HWO  var as needed


PLACEMENT=./PLACEMENTS/hw2hw-bidir-2pairs 
#HWOL="--hwol"
HWOL=""

SAMPLES=6 NTHREADS=16 DURATION=30 WSIZE=32000 PLACEMENT=$PLACEMENT ./start-client "${HWOL}"

