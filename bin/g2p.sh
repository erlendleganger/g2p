#!/bin/bash
#---------------------------------------------------------------------------
export BASEDIR=$(cd $(dirname $0);pwd)
export BASENAME=$(echo $(basename $0)|sed "s/\..*//")
export PLCFGFILE=$BASEDIR/$BASENAME-ini.pl
export SHCFGFILE=$BASEDIR/$BASENAME-ini.sh
export PLFILE=$BASEDIR/$BASENAME.pl
echo BASEDIR=$BASEDIR
echo PLCFGFILE=$PLCFGFILE
echo SHCFGFILE=$SHCFGFILE
echo BASENAME=$BASENAME

#---------------------------------------------------------------------------
for F in $SHCFGFILE $PLCFGFILE $PLFILE; do
   if [ ! -f $F ]; then
      echo error - cannot find $F
      exit 1
   fi
done

#---------------------------------------------------------------------------
#load config
source $SHCFGFILE

#---------------------------------------------------------------------------
#parse parameters?

#---------------------------------------------------------------------------
#run main script
perl $PLFILE

#---------------------------------------------------------------------------
echo this is $0
echo
echo hit return to exit
read key
