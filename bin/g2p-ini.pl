#------------------------------------------------------------------------
my %cfgdb;

#------------------------------------------------------------------------
$cfgdb{USER}{NAME}="Erlend Leganger";
@{$cfgdb{USER}{HRZONES}}=([190],[186],[179],[175],[168],[159],[149],[50],[0],[0],[0]);
@{$cfgdb{USER}{TRIP}}=([0],[0],[0],[0],[0],[0],[0],[0]);
#print Dumper(%cfgdb);
#print "premature\n"; exit 1;

#------------------------------------------------------------------------
sub get_cfgdb{\%cfgdb;}

#------------------------------------------------------------------------
1;
