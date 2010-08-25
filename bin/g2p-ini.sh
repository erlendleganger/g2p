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
export POLARDIR="D:\\user\\elega\\personal\\trening\\polar\\Erlend Leganger\\$(date "+%Y")"
export POLARDIR="D:\\bruker\\erlend\\personlig\\trening\\polar\\Erlend Leganger\\$(date "+%Y")"

#---------------------------------------------------------------------------
#get_timestamp_filename
#return the name of the time stamp file for the passed id
#parameters:
#- $1: the directory containing the timestamp file
#- $2: the id for the timestamp file
#sample call: timestampfile=$(get_timestamp_filename $dir $id)
#---------------------------------------------------------------------------
get_timestamp_filename(){
   echo $1/timestamp-$2.txt
}
