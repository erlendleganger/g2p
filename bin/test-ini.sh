#------------------------------------------------------------------------
#the date to generate test data for
TEST_YYYY=2010
TEST_MM=07
TEST_DD=31
TEST_BACKUPDIR=

#------------------------------------------------------------------------

#------------------------------------------------------------------------
#calculated settings
TEST_BASEDIR=$(cd $(dirname $0)/..;pwd)
TEST_TGTDIR=$TEST_BASEDIR/gen
TEST_BACKUPDIR=$TEST_BASEDIR/backup
TEST_YY=${TEST_YYYY:2:2}
TEST_HRMFILEPATTERN=${TEST_YY}${TEST_MM}${TEST_DD}??.hrm
TEST_PDDFILE=${TEST_YYYY}${TEST_MM}${TEST_DD}.pdd

#------------------------------------------------------------------------
#initialising code
mkdir -p $TEST_TGTDIR
mkdir -p $TEST_BACKUPDIR
