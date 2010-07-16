#!/bin/bash
TGTDIR="/cygdrive/d/bruker/erlend/personlig/trening/polar/Erlend Leganger/2010"
for F in tmp/10071501.hrm tmp/20100715.pdd; do
   cp -p $F "$TGTDIR"
   cp -p $F /cygdrive/c/tmp
done
