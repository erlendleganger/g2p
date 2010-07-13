#---------------------------------------------------------------------------
use strict;
use XML::Parser::Expat;
use Data::Dumper;
my $TotalTimeSeconds;
my $tcxfile="./testdata/run-0.tcx";
my %db;
my $currval;


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
my $L="-"x72;
my $file;
my $fileprefix="xml-parser-expat";
my $datadir="./tmp";
my $fileAircraftModel="$fileprefix-AircraftModel.txt";
my $fileAircraftConfiguration="$fileprefix-AircraftConfiguration.txt";
my $fileAircraftConfigurationStoreItem="$fileprefix-AircraftConfigurationStoreItem.txt";
my $fileOperatingLocation="$fileprefix-OperatingLocation.txt";

#---------------------------------------------------------------------------
#get the initialisation file
my $cfgfile="$ENV{CFGFILE}";
if(-f $cfgfile){
   require $cfgfile;
}
else{
   die "cannot find $cfgfile";
}

#---------------------------------------------------------------------------
my $rcfgdb;
if(defined &get_cfgdb){
   $rcfgdb=get_cfgdb();
}
else{
   die "cannot get cfgdb";
}
print Dumper(%$rcfgdb);
print "$$rcfgdb{USER}{NAME}\n";
print "premature\n";exit 1;

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
#do the job - parse the tcx file
open TCX,"<$tcxfile" or die "cannot open $tcxfile";
print "parsing $tcxfile...\n";
$parser->parse(*TCX);
close(TCX);

#---------------------------------------------------------------------------
#dump datastructure for debugging
#print Dumper(%AircraftModel);


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
   #print "start_element: el=$el\n";
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub end_element{
   my ($p, $el) = @_;
   #print "end_element: el=$el\n";
   if($el eq "Lap"){
      print "Lap completed: TotalTimeSeconds=$TotalTimeSeconds\n";
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

__DATA__
key n2:AircraftModel: n2:aircraftConfigurations
key n2:AircraftModel: n2:aircraftType
key n2:AircraftModel: n2:combatRadius
key n2:AircraftModel: n2:dayAndNightCapabilityCode
key n2:AircraftModel: n2:defaultTaskedQuantity
key n2:AircraftModel: n2:enduranceTime
key n2:AircraftModel: n2:fuelReserveWeightCapacity
key n2:AircraftModel: n2:fuelType
key n2:AircraftModel: n2:grossWeight
key n2:AircraftModel: n2:highAltitudeBurnRate
key n2:AircraftModel: n2:internalFuelWeightCapacity
key n2:AircraftModel: n2:lastModified
key n2:AircraftModel: n2:lowAltitudeBurnRate
key n2:AircraftModel: n2:mediumAltitudeBurnRate
key n2:AircraftModel: n2:refuelingOnloadRate
key n2:AircraftModel: n2:refuelingSystemType
key n2:AircraftModel: xsi:type
key n193:StoreItem: n193:itemCode
key n193:StoreItem: n193:jammerBandwidths
key n193:StoreItem: n193:jammerFieldOfView
key n193:StoreItem: n193:lastModified
key n193:StoreItem: n193:nominalRange
key n193:StoreItem: n193:nominalSpeed
key n193:StoreItem: n193:notes
key n193:StoreItem: n193:reusable
key n193:StoreItem: n193:standoffWeaponType
key n193:StoreItem: n193:typeCode
key n194:TaskableUnit: n194:airDefenseUnitWeaponSystems
key n194:TaskableUnit: n194:aircraftUnitLocations
key n194:TaskableUnit: n194:comments
key n194:TaskableUnit: n194:contacts
key n194:TaskableUnit: n194:country
key n194:TaskableUnit: n194:function
key n194:TaskableUnit: n194:geodetic
key n194:TaskableUnit: n194:groundControlUnitEquipment
key n194:TaskableUnit: n194:icao
key n194:TaskableUnit: n194:id
key n194:TaskableUnit: n194:lastModified
key n194:TaskableUnit: n194:locationName
key n194:TaskableUnit: n194:missileUnitWeaponSystems
key n194:TaskableUnit: n194:operatingStatus
key n194:TaskableUnit: n194:parentCountry
key n194:TaskableUnit: n194:parentId
key n194:TaskableUnit: n194:position
key n194:TaskableUnit: n194:positionDateTime
key n194:TaskableUnit: n194:reportDateTime
key n194:TaskableUnit: n194:service
key n194:TaskableUnit: n194:taskedDesignator
key n194:TaskableUnit: n194:taskingAgencyName
key n194:TaskableUnit: xsi:type
key n4:OperatingLocation: n4:availabilities
key n4:OperatingLocation: n4:country
key n4:OperatingLocation: n4:elevation
key n4:OperatingLocation: n4:geodetic
key n4:OperatingLocation: n4:icao
key n4:OperatingLocation: n4:inJFACCAreaOfResponsibility
key n4:OperatingLocation: n4:lastModified
key n4:OperatingLocation: n4:locationStoreItems
key n4:OperatingLocation: n4:mobilePosition
key n4:OperatingLocation: n4:name
key n4:OperatingLocation: n4:operatingStatus
key n4:OperatingLocation: n4:runways
key n4:OperatingLocation: n4:service
key n4:OperatingLocation: n4:statusValidUntilDateTime
key n4:OperatingLocation: n4:supportsAirOperations
key n4:OperatingLocation: n4:weatherColorCode
done
