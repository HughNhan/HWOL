#!/bin/bash

#
# Usage: HWOL=<true/false> this-run --label
# Option: change HWO var as needed
# 

PLACEMENT=./PLACEMENTS/1pair-colocate
export HWOL=${HWOL:-false}
export NTHREADS=${NTHREADS:-1}

SAMPLES=1 NTHREADS=$NTHREADS DURATION=10 WSIZE=32000 PLACEMENT=$PLACEMENT HWOL=$HWOL iperf-start

