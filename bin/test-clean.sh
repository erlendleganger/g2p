#!/bin/bash
#------------------------------------------------------------------------
source $(dirname $0)/g2p-ini.sh
source $(dirname $0)/test-ini.sh

#------------------------------------------------------------------------
echo cleaning up files for $TEST_YYYY-$TEST_MM-$TEST_DD...
for D in "$POLARDIR" "$TEST_TGTDIR"; do
   (cd "$D"; rm -f $TEST_HRMFILEPATTERN $TEST_PDDFILE)
done
