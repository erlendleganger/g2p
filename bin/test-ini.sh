#------------------------------------------------------------------------
#the date to generate test data for
TEST_YYYY=2010
TEST_MM=07
TEST_DD=22

#------------------------------------------------------------------------
TEST_TGTDIR=$(dirname $0)/gen

#------------------------------------------------------------------------
#calculated settings
TEST_YY=${TEST_YYYY:2:2}
TEST_HRMFILEPATTERN=${TEST_YY}${TEST_MM}${TEST_DD}??.hrm
TEST_PDDFILE=${TEST_YYYY}${TEST_MM}${TEST_DD}.pdd

#------------------------------------------------------------------------
#initialising code
mkdir -p $TEST_TGTDIR
