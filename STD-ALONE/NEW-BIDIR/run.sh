#!/bin/bash

#
# Usage: HWOL=<true/false> this-run --label
# Option: change HWO var as needed
# 

PLACEMENT=./PLACEMENTS/hw2hw-bidir-2pairs 
export HWOL=${HWOL:-false}
export NTHREADS=${NTHREADS:-1}

#PLACEMENT=$PLACEMENT ./make-pod-spec

SAMPLES=6 NTHREADS=$NTHREADS DURATION=30 WSIZE=32000 PLACEMENT=$PLACEMENT HWOL=$HWOL ./start-client 

