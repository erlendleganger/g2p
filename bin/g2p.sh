#!/bin/bash
#---------------------------------------------------------------------------
export BINDIR=$(cd $(dirname $0);pwd)
export BASENAME=$(echo $(basename $0)|sed "s/\..*//")
export PLCFGFILE=$BINDIR/$BASENAME-ini.pl
export SHCFGFILE=$BINDIR/$BASENAME-ini.sh
export PLFILE=$BINDIR/$BASENAME.pl
export OUTDIR=$(cd $(dirname $0)/..;pwd)/tmp
export HRMFILEOUTPUT=$OUTDIR/gen-0.hrm
export TCXFILEOUTPUT=$OUTDIR/gen-0.tcx
#echo BINDIR=$BINDIR
echo OUTDIR=$OUTDIR
#echo PLCFGFILE=$PLCFGFILE
#echo SHCFGFILE=$SHCFGFILE
#echo BASENAME=$BASENAME

#---------------------------------------------------------------------------
#check that all files are there
for F in $SHCFGFILE $PLCFGFILE $PLFILE; do
   if [ ! -f $F ]; then
      echo error - cannot find $F
      exit 1
   fi
done

#---------------------------------------------------------------------------
#load config
echo loading $SHCFGFILE...
source $SHCFGFILE

#---------------------------------------------------------------------------
#parse parameters?

#---------------------------------------------------------------------------
export TCXFILEINPUT=$(find $TCXDIR -type f|sort|tail -1)
if [ ! -f $TCXFILEINPUT ]; then
   echo error - cannot open $TCXFILEINPUT
fi

#---------------------------------------------------------------------------
#run main script
perl $PLFILE

#---------------------------------------------------------------------------
echo this is $0
#echo
#echo hit return to exit
#read key
