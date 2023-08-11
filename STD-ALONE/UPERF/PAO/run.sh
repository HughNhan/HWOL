#!/bin/bash

#
# Usage: HWOL=<true/false> this-run --label
# Option: change HWO var as needed
# 

#PLACEMENT=./PLACEMENTS/hw2hw-server-1pair
PLACEMENT=./PLACEMENTS/intra-1pair
export HWOL=${HWOL:-false}
export NTHREADS=${NTHREADS:-1}

CPUS=1 SAMPLES=1 NTHREADS=$NTHREADS DURATION=30 WSIZE=32000 PLACEMENT=$PLACEMENT HWOL=$HWOL uperf-start

