#---------------------------------------------------------------------------
use strict;
use XML::Parser::Expat;
use Data::Dumper;
my $tcxfile="$ENV{TCXFILEINPUT}";
my %db;
my $currval;

#---------------------------------------------------------------------------
my %tcxdb;
my $TotalTimeSeconds;
my $Id;
my $Sport;
my $StartTime;


my $aircraftType;
my $fuelType;
my $combatRadius;
my %AircraftModel; #key: aircraftType
my %AircraftConfiguration; #key: aircraftType, configurationId
my %AircraftConfigurationStoreItem;
my %OperatingLocation;
my %Runway;
my %geodetic;
my $datum;
my $height;
my $latitude;
my $longitude;
my $configurationId;
my $actionRadius;
my $externalFuelWeightCapacity;
my $storeItemCode;
my $itemQuantity;
my $weatherColorCode;
my $name;
my $elevation;
my $icao;
my $sep=",";
my $L="-"x75;
my $file;
my $fileprefix="xml-parser-expat";
my $datadir="./tmp";
my $fileAircraftModel="$fileprefix-AircraftModel.txt";
my $fileAircraftConfiguration="$fileprefix-AircraftConfiguration.txt";
my $fileAircraftConfigurationStoreItem="$fileprefix-AircraftConfigurationStoreItem.txt";
my $fileOperatingLocation="$fileprefix-OperatingLocation.txt";


#---------------------------------------------------------------------------
#load the initialisation file
my $cfgfile="$ENV{PLCFGFILE}";
if(-f $cfgfile){
   print "loading $cfgfile...\n";
   require $cfgfile;
}
else{
   die "cannot find $cfgfile";
}

#---------------------------------------------------------------------------
#get the cfg db
my $rcfgdb;
if(defined &get_cfgdb){
   $rcfgdb=get_cfgdb();
}
else{
   die "cannot get cfgdb";
}
#print Dumper(%$rcfgdb);
#print "$$rcfgdb{USER}{NAME}\n";
#print "premature\n";exit 1;

#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
#create parser object which is namespace-aware
my $parser = new XML::Parser::Expat('Namespaces' =>1);

#---------------------------------------------------------------------------
#set handlers for tags and data
$parser->setHandlers('Start' => \&start_element,
                     'End'   => \&end_element,
                     'Char'  => \&char_data,
                     );

#---------------------------------------------------------------------------
#get
#my ($yy,$mm,$dd,$tt,$rest)=split/-/,$tcxfile;
#print "yy=$yy, mm=$mm, dd=$dd\n";
#print "premature\n";exit 1;

#---------------------------------------------------------------------------
#parse the tcx file
open TCX,"<$tcxfile" or die "cannot open $tcxfile";
print "parsing $tcxfile...\n";
$parser->parse(*TCX);
close(TCX);

#---------------------------------------------------------------------------
#dump datastructure for debugging
print Dumper(%tcxdb);


#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub char_data{
   my ($p,$string)=@_;
   $currval=$string;
   $currval=~s/^\s*//;
   $currval=~s/\s*$//;
   #print "char_data: currval=$currval\n" if($currval);
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub start_element{
   my ($p, $el, %atts) = @_;
   if($el eq "Activity"){
      $Sport=$atts{Sport};
   }
   elsif($el eq "Lap"){
      $StartTime=$atts{StartTime};
   }
   #print "start_element: el=$el\n";
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub end_element{
   my ($p, $el) = @_;
   #print "end_element: el=$el\n";
   if($el eq "Activity"){
      print "Activity completed: Sport=$Sport, Id=$Id\n";
      $tcxdb{$Id}{Sport}=$Sport;
   }
   elsif($el eq "Lap"){
      $tcxdb{$Id}{Lap}{$StartTime}{TotalTimeSeconds}=$TotalTimeSeconds;
      print "Lap completed: TotalTimeSeconds=$TotalTimeSeconds\n";
   }
   elsif($el eq "Id"){
      $Id=$currval;
   }
   elsif($el eq "TotalTimeSeconds"){
      $TotalTimeSeconds=$currval;
   }
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub cwid_start_element{
  my ($p, $el, %atts) = @_;
  if($el eq "AircraftModel"){
     1;
  }
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub cwid_end_element{
   my ($p, $el) = @_;
   if($el eq "AircraftModel"){

      #---------------------------------------------------------------------
      #pick up values for this aircraft model
      $AircraftModel{$aircraftType}{"fuelType"}=$fuelType;
      $AircraftModel{$aircraftType}{"combatRadius"}=$combatRadius;

      #---------------------------------------------------------------------
      #copy the found aircraft configurations for this aircraft model
      for(keys %AircraftConfiguration){
         $AircraftModel{$aircraftType}{"AircraftConfigurations"}{$_}=
            \%{$AircraftConfiguration{$_}};
      }

      #---------------------------------------------------------------------
      #empty the configuration hash for the next aircraft model
      %AircraftConfiguration=();
   }
   elsif($el eq "aircraftType"){
      $aircraftType=$currval;
   }
   elsif($el eq "fuelType"){
      $fuelType=$currval;
   }
   elsif($el eq "combatRadius"){
      $combatRadius=$currval;
   }
   elsif($el eq "AircraftConfiguration"){
      $AircraftConfiguration{$configurationId}{"actionRadius"}=$actionRadius;
      $AircraftConfiguration{$configurationId}{"externalFuelWeightCapacity"}=$externalFuelWeightCapacity;

      #---------------------------------------------------------------------
      #copy the found store items for this aircraft configuration
      for(keys %AircraftConfigurationStoreItem){
         #print "$configurationId, key=$_\n";
         $AircraftConfiguration{$configurationId}{"AircraftConfigurationStoreItem"}{$_}=\%{$AircraftConfigurationStoreItem{$_}};
      }

      #---------------------------------------------------------------------
      #empty the store item hash for the next aircraft configuration
      %AircraftConfigurationStoreItem=();
   }
   elsif($el eq "aircraftType"){
      $aircraftType=$currval;
   }
   elsif($el eq "fuelType"){
      $fuelType=$currval;
   }
   elsif($el eq "combatRadius"){
      $combatRadius=$currval;
   }
   elsif($el eq "AircraftConfiguration"){
      $AircraftConfiguration{$configurationId}{"actionRadius"}=$actionRadius;
      $AircraftConfiguration{$configurationId}{"externalFuelWeightCapacity"}=$externalFuelWeightCapacity;
      
   }
   elsif($el eq "configurationId"){
      $configurationId=$currval;
   }
   elsif($el eq "actionRadius"){
      $actionRadius=$currval;
   }
   elsif($el eq "externalFuelWeightCapacity"){
      $externalFuelWeightCapacity=$currval;
   }
   elsif($el eq "AircraftConfigurationStoreItem"){
      $AircraftConfigurationStoreItem{$storeItemCode}{"itemQuantity"}=$itemQuantity;
   }      
   elsif($el eq "storeItemCode"){
      $storeItemCode=$currval;
   }
   elsif($el eq "itemQuantity"){
      $itemQuantity=$currval;
   }
   elsif($el eq "OperatingLocation"){
      $OperatingLocation{$icao}{"name"}=$name;
      $OperatingLocation{$icao}{"elevation"}=$elevation;
      $OperatingLocation{$icao}{"weatherColorCode"}=$weatherColorCode;
      if(defined %geodetic){
         for(keys %geodetic){
            $OperatingLocation{$icao}{"geodetic"}{$_}=$geodetic{$_};
         }
         %geodetic=();
      }
   }
   elsif($el eq "name"){
      $name=$currval;
   }
   elsif($el eq "weatherColorCode"){
      $weatherColorCode=$currval;
   }
   elsif($el eq "elevation"){
      $elevation=$currval;
   }
   elsif($el eq "icao"){
      $icao=$currval;
      #print "icao, namespace: ",$parser->namespace($el),"\n";
   }
   elsif($el eq "geodetic"){
      $geodetic{"datum"}=$datum;
      $geodetic{"height"}=$height;
      $geodetic{"longitude"}=$longitude;
      $geodetic{"latitude"}=$latitude;
   }
   elsif($el eq "datum"){
      $datum=$currval;
   }
   elsif($el eq "height"){
      $height=$currval;
   }
   elsif($el eq "latitude"){
      $latitude=$currval;
   }
   elsif($el eq "longitude"){
      $longitude=$currval;
   }
}  
