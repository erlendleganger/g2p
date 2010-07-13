#!/bin/bash
#---------------------------------------------------------------------------
export BASEDIR=$(cd $(dirname $0);pwd)
export BASENAME=$(echo $(basename $0)|sed "s/\..*//")
export CFGFILE=$BASEDIR/$BASENAME.ini
export PLFILE=$BASEDIR/$BASENAME.pl
echo BASEDIR=$BASEDIR
echo CFGFILE=$CFGFILE
echo BASENAME=$BASENAME

#---------------------------------------------------------------------------
for F in $CFGFILE $PLFILE; do
   if [ ! -f $F ]; then
      echo error - cannot find $F
   fi
done

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
