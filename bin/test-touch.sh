#!/bin/bash
#------------------------------------------------------------------------
source $(dirname $0)/g2p-ini.sh
source $(dirname $0)/test-ini.sh

#------------------------------------------------------------------------
id=${aID[1]}
srcdir=${aSRCDIR[1]}

#------------------------------------------------------------------------
if [ $id = "e500" ]; then
   timestampfile=$(get_timestamp_filename "$srcdir" $id)
   touch -t ${TEST_YY}${TEST_MM}${TEST_DD}0000 $timestampfile
   ls -altr $srcdir
else
   echo error - id=$id is not correct
fi
