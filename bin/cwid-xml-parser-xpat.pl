#---------------------------------------------------------------------------
my $conclusion="
TBD
";

#---------------------------------------------------------------------------
use strict;
use XML::Parser::Expat;
use Data::Dumper;
my $frobfile="./testdata/getFrOBResponse.xml";
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
#open output files
#$file="$datadir/$fileAircraftModel";
#open ACFTMODEL,">$file" or die "cannot create $file";
#$file="$datadir/$fileAircraftConfiguration";
#open ACFTCONF,">$file" or die "cannot create $file";

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
#do the job - parse the FrOB
open FROB,"<$frobfile" or die "cannot open $frobfile";
print "parsing $frobfile...\n";
$parser->parse(*FROB);
close(FROB);

#---------------------------------------------------------------------------
#close files
#close ACFTMODEL;
#close ACFTCONF;

#---------------------------------------------------------------------------
#make report
$file="$datadir/$fileAircraftModel";
print "creating $file...\n";
open OUT,">$file" or die "cannot create $file";
for(sort keys %AircraftModel){
   print OUT "$_$sep";
   print OUT "$AircraftModel{$_}{fuelType}$sep";
   print OUT "$AircraftModel{$_}{combatRadius}$sep";
   print OUT "\n";
}
close OUT;

##---------------------------------------------------------------------------
##make report
#$file="$datadir/$fileAircraftConfiguration";
#print "creating $file...\n";
#open OUT,">$file" or die "cannot create $file";
#for $aircraftType(sort keys %AircraftModel){
#   for $configurationId(sort keys %{$AircraftModel{$aircraftType}{"AircraftConfigurations"}}){
#      print OUT "$aircraftType$sep";
#      print OUT "$configurationId$sep";
#      print OUT "$AircraftModel{$aircraftType}{AircraftConfigurations}{$configurationId}{actionRadius}$sep";
#      print OUT "$AircraftModel{$aircraftType}{AircraftConfigurations}{$configurationId}{externalFuelWeightCapacity}$sep";
#      print OUT "\n";
#   }
#}
#close OUT;

#---------------------------------------------------------------------------
#make report
$file="$datadir/$fileAircraftConfiguration";
print "creating $file...\n";
open OUT,">$file" or die "cannot create $file";
for $aircraftType(sort keys %AircraftModel){
   my $href=$AircraftModel{$aircraftType}{"AircraftConfigurations"};
   for $configurationId(sort keys %$href){
      print OUT "$aircraftType$sep";
      print OUT "$configurationId$sep";
      print OUT "${$href}{$configurationId}{actionRadius}$sep";
      print OUT "${$href}{$configurationId}{externalFuelWeightCapacity}$sep";
      print OUT "\n";
   }
}
close OUT;

#---------------------------------------------------------------------------
#make report
$file="$datadir/$fileAircraftConfigurationStoreItem";
print "creating $file...\n";
open OUT,">$file" or die "cannot create $file";
for $aircraftType(sort keys %AircraftModel){
   my $href0=$AircraftModel{$aircraftType}{"AircraftConfigurations"};
   #print "$L\n",Dumper(%$href0);
   for $configurationId(sort keys %$href0){
      my $href1=${$href0}{$configurationId}{"AircraftConfigurationStoreItem"};
      for $storeItemCode(sort keys %$href1){
         print OUT "$aircraftType$sep";
         print OUT "$configurationId$sep";
         print OUT "$storeItemCode$sep";
         print OUT "${$href1}{$storeItemCode}{itemQuantity}$sep";
         print OUT "\n";
      }
   }
}
close OUT;

#---------------------------------------------------------------------------
#make report
$file="$datadir/$fileOperatingLocation";
print "creating $file...\n";
open OUT,">$file" or die "cannot create $file";
for $icao(sort keys %OperatingLocation){
   my $href=$OperatingLocation{$icao};
   print OUT "$icao$sep";
   print OUT "${$href}{name}$sep";
   print OUT "${$href}{elevation}$sep";
   print OUT "${$href}{geodetic}{datum}$sep";
   print OUT "${$href}{geodetic}{height}$sep";
   print OUT "${$href}{geodetic}{latitude}$sep";
   print OUT "${$href}{geodetic}{longitude}$sep";
   print OUT "\n";
}
close OUT;

#---------------------------------------------------------------------------
#dump datastructure for debugging
#print Dumper(%AircraftModel);

#---------------------------------------------------------------------------
#make report
#print "$L\n";
#for my $a(sort keys %AircraftConfiguration){
#   for my $b(sort keys %{$AircraftConfiguration{$a}}){
#      print "$a, $b\n";
#   }
#}


#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub char_data{
   my ($p,$string)=@_;
   $currval=$string;
   $currval=~s/^\s*//;
   $currval=~s/\s*$//;
   #print "currval=$currval\n";
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub start_element{
  my ($p, $el, %atts) = @_;
  if($el eq "AircraftModel"){
     1;
  }
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub end_element{
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
