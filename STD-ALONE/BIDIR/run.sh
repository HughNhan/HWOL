#!/bin/bash

#
# Usage: HWOL=<true/false> this-run --label
# Option: change HWO var as needed

PLACEMENT=./PLACEMENTS/hw2hw-bidir-2pairs 
export HWOL=${HWOL:-false}

SAMPLES=6 NTHREADS=12 DURATION=3000 WSIZE=32000 PLACEMENT=$PLACEMENT HWOL=$HWOL ./start-client 

