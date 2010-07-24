#!/bin/bash
#------------------------------------------------------------------------
source $(dirname $0)/g2p-ini.sh
source $(dirname $0)/test-ini.sh

#------------------------------------------------------------------------
for D in "$POLARDIR" "$TEST_TGTDIR"; do
   for F in $TEST_HRMFILEPATTERN $TEST_PDDFILE; do
      ls "$D"/$F
   done
done
