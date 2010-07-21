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
#echo OUTDIR=$OUTDIR
#echo PLCFGFILE=$PLCFGFILE
#echo SHCFGFILE=$SHCFGFILE
#echo BASENAME=$BASENAME
L=------------------------------------------------------------------------

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
#check output directory
if [ -z "$POLARDIR" ]; then
   echo "error - POLARDIR not set"
   exit 1
else
   if [ ! -d "$POLARDIR" ]; then
      echo "error - POLARDIR=$POLARDIR does not exist"
      exit 1
   fi
fi

#---------------------------------------------------------------------------
I=0
while [ $I -lt ${#aID[@]} ]; do
   #------------------------------------------------------------------------
   export ID=${aID[$I]}
   SRCDIR=${aSRCDIR[$I]}
   PATTERN=${aPATTERN[$I]}
   TIMESTAMP=$SRCDIR/timestamp-$ID.txt
   #echo SRCDIR=$SRCDIR
   #echo TIMESTAMP=$TIMESTAMP

   #------------------------------------------------------------------------
   echo $L
   if [ -d $SRCDIR ]; then
      #------------------------------------------------------------------------
      [ -f $TIMESTAMP ] || date>$TIMESTAMP

      #------------------------------------------------------------------------
      echo searching $SRCDIR...
      for INFILE in $(find $SRCDIR -type f -prune -name "$PATTERN" -newer $TIMESTAMP); do
         echo $L
         echo file: $(basename $INFILE)
         export INFILE
         perl $PLFILE
      done
   
      #------------------------------------------------------------------------
      #touch -r bin/cwid-xml-parser-xpat.pl $TIMESTAMP
      touch $TIMESTAMP
   else
      echo warning - cannot find $SRCDIR
   fi

   #------------------------------------------------------------------------
   I=$((++I))
done

#---------------------------------------------------------------------------
#echo
#echo hit return to exit
#read key
