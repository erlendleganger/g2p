#---------------------------------------------------------------------------
TCXDIR=C:\\Users\\Erlend\\AppData\\Roaming\\GARMIN\\Devices\\3683510935\\History
#---------------------------------------------------------------------------
aID=(fr310xt e500 tacx)

#---------------------------------------------------------------------------
aSRCDIR=(
C:\\Users\\Erlend\\AppData\\Roaming\\GARMIN\\Devices\\3683510935\\History
D:\\bruker\\erlend\\personlig\\trening\\garmin\\enhet\\edge500\\Garmin\\Activities
\\\\sempron3000\\Public\\tacx
)

#---------------------------------------------------------------------------
aPATTERN=(*.TCX *.fit *.hrm)

#---------------------------------------------------------------------------
export POLARDIR="testdata\\Erlend Leganger\\$(date "+%Y")"
export POLARDIR=/cygdrive/c/tmp
export POLARDIR="D:\\bruker\\erlend\\personlig\\trening\\polar\\Erlend Leganger\\$(date "+%Y")"

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
get_timestamp_filename(){
   echo $1/timestamp-$2.txt
}
