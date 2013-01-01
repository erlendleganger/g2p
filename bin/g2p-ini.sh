#---------------------------------------------------------------------------
#version information
export g2pvernum="1.2"
export g2pverdate="2013-01-01"

#---------------------------------------------------------------------------
#array with types of device to pick up data from
aID=(
910xt 
e800
)
#fr310xt 
#e500
#tacx

#---------------------------------------------------------------------------
#array with source directories for the device types above - must match
#one-to-one with the aID array
aSRCDIR=(
C:\\Users\\Erlend\\AppData\\Roaming\\GARMIN\\Devices\\3842636421\\Activities
D:\\bruker\\erlend\\personlig\\trening\\garmin\\enhet\\edge800\\Garmin\\Activities
)
#C:\\Users\\Erlend\\AppData\\Roaming\\GARMIN\\Devices\\3842636421\\History
#C:\\Users\\Erlend\\AppData\\Roaming\\GARMIN\\Devices\\3683510935\\History
#D:\\bruker\\erlend\\personlig\\trening\\garmin\\enhet\\edge500\\Garmin\\Activities
#D:\\user\\Erlend\\personal\\trening\\garmin\\enhet\\edge500\\Garmin\\Activities
#\\\\sempron3000\\Public\\tacx

#---------------------------------------------------------------------------
#file name patterns for files to pick up from the aSRCDIR entries above;
#must match one-to-one with the aID and aSRCDIR arrays
aPATTERN=(
*.FIT
*.fit)
#*.fit
#*.hrm

#---------------------------------------------------------------------------
#find target directory for the generated Polar files
year=$(date "+%Y")
#year=2012 #activate this for sessions made before and logged after 1 jan
export POLARDIR="unset"
dir=D:\\bruker\\erlend\\personlig\\trening\\polar\\Erlend\ Leganger\\$year
[ -d "$dir" ] && POLARDIR=$dir
dir=D:\\user\\Erlend\\personal\\trening\\polar\\Erlend\ Leganger\\$year
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
