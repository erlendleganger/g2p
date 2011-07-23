#---------------------------------------------------------------------------
#array with types of device to pick up data from
aID=(
fr310xt 
e500
e500
tacx)

#---------------------------------------------------------------------------
#array with source directories for the device types above - must match
#one-to-one with the aID array
aSRCDIR=(
C:\\Users\\Erlend\\AppData\\Roaming\\GARMIN\\Devices\\3683510935\\History
D:\\bruker\\erlend\\personlig\\trening\\garmin\\enhet\\edge500\\Garmin\\Activities
D:\\user\\Erlend\\personal\\trening\\garmin\\enhet\\edge500\\Garmin\\Activities
\\\\sempron3000\\Public\\tacx
)

#---------------------------------------------------------------------------
#file name patterns for files to pick up from the aSRCDIR entries above;
#must match one-to-one with the aID and aSRCDIR arrays
aPATTERN=(
*.TCX
*.fit
*.fit
*.hrm)

#---------------------------------------------------------------------------
#find target directory for the generated Polar files
export POLARDIR="testdata\\Erlend Leganger\\$(date "+%Y")"
export POLARDIR="unset"
dir=D:\\bruker\\erlend\\personlig\\trening\\polar\\Erlend\ Leganger\\$(date "+%Y")
[ -d "$dir" ] && POLARDIR=$dir
dir=D:\\user\\Erlend\\personal\\trening\\polar\\Erlend\ Leganger\\$(date "+%Y")
[ -d "$dir" ] && POLARDIR=$dir

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
