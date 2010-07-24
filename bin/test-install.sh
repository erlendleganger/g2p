#!/bin/bash
#------------------------------------------------------------------------
source $(dirname $0)/g2p-ini.sh
source $(dirname $0)/test-ini.sh

#------------------------------------------------------------------------
for F in $TEST_HRMFILEPATTERN $TEST_PDDFILE; do
   echo unix2dos $TEST_TGTDIR/$F
   echo cp -p $TEST_TGTDIR/$F "$POLARDIR"
   echo ls "$D"/$F
done
