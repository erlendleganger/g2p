#!/bin/bash
#------------------------------------------------------------------------
source $(dirname $0)/g2p-ini.sh
source $(dirname $0)/test-ini.sh

#------------------------------------------------------------------------
cd "$POLARDIR"
tarball=$TEST_BACKUPDIR/$(date "+%Y-%m-%d-%H%M%S").tar.gz
echo creating $(basename $tarball)...
tar cvfz $tarball $TEST_PDDFILE $TEST_HRMFILEPATTERN 
echo done
