#---------------------------------------------------------------------------
use strict;
use XML::Parser::Expat;
use HTTP::Date;
use Data::Dumper;
$Data::Dumper::Indent = 1;
my $tcxfilein="$ENV{TCXFILEINPUT}";
my $tcxfileout="$ENV{TCXFILEOUTPUT}";
my $hrmfile="$ENV{HRMFILEOUTPUT}";
my %db;
my $currval;

#---------------------------------------------------------------------------
my %tcxdb;
my %hrmdb;
my $AltitudeMeters;
my $BuildMajor;
my $BuildMinor;
my $Builder;
my $DistanceMeters;
my $HeartRateBpm;;
my $Id;
my $LangID;
my $Name;
my $PartNumber;
my $RunCadence;
my $Speed;
my $Sport;
my $StartTime;
my $Time;
my $TotalTimeSeconds;
my $Type;
my $Value;
my $VersionMajor;
my $VersionMinor;

#---------------------------------------------------------------------------
#initialise static settings
my $order=0;
$hrmdb{Params}{Version}{order}=$order++;
$hrmdb{Params}{Version}{payload}="106";
$hrmdb{Params}{Monitor}{order}=$order++;
$hrmdb{Params}{Monitor}{payload}="12";
$hrmdb{Params}{SMode}{order}=$order++;
$hrmdb{Params}{SMode}{payload}="111111100";
$hrmdb{Params}{Date}{order}=$order++;
$hrmdb{Params}{Date}{payload}="20100712";
$hrmdb{Params}{StartTime}{order}=$order++;
$hrmdb{Params}{StartTime}{payload}="19:05:09.0";
$hrmdb{Params}{Length}{order}=$order++;
$hrmdb{Params}{Length}{payload}="01:55:36.0";
$hrmdb{Params}{Interval}{order}=$order++;
$hrmdb{Params}{Interval}{payload}="1";
$hrmdb{Params}{Upper1}{order}=$order++;
$hrmdb{Params}{Upper1}{payload}="0";
$hrmdb{Params}{Lower1}{order}=$order++;
$hrmdb{Params}{Lower1}{payload}="0";
$hrmdb{Params}{Upper2}{order}=$order++;
$hrmdb{Params}{Upper2}{payload}="0";
$hrmdb{Params}{Lower2}{order}=$order++;
$hrmdb{Params}{Lower2}{payload}="0";
$hrmdb{Params}{Upper3}{order}=$order++;
$hrmdb{Params}{Upper3}{payload}="0";
$hrmdb{Params}{Lower3}{order}=$order++;
$hrmdb{Params}{Lower3}{payload}="0";
$hrmdb{Params}{Timer1}{order}=$order++;
$hrmdb{Params}{Timer1}{payload}="00:00:00.0";
$hrmdb{Params}{Timer2}{order}=$order++;
$hrmdb{Params}{Timer2}{payload}="00:00:00.0";
$hrmdb{Params}{Timer3}{order}=$order++;
$hrmdb{Params}{Timer3}{payload}="00:00:00.0";
$hrmdb{Params}{ActiveLimit}{order}=$order++;
$hrmdb{Params}{ActiveLimit}{payload}="0";
$hrmdb{Params}{MaxHR}{order}=$order++;
$hrmdb{Params}{MaxHR}{payload}="190";
$hrmdb{Params}{RestHR}{order}=$order++;
$hrmdb{Params}{RestHR}{payload}="60";
$hrmdb{Params}{StartDelay}{order}=$order++;
$hrmdb{Params}{StartDelay}{payload}="0";
$hrmdb{Params}{VO2max}{order}=$order++;
$hrmdb{Params}{VO2max}{payload}="30";
$hrmdb{Params}{Weight}{order}=$order++;
$hrmdb{Params}{Weight}{payload}="97";

#---------------------------------------------------------------------------
#go through this section for deletion
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

sub mydump{
my $id=shift;
my $key=shift;
print "start: dump $key\n";
for $Time(sort keys %{$tcxdb{Activity}{$id}{Trackpoint}}){
   print "Time=$Time, $key=$tcxdb{Activity}{$id}{Trackpoint}{$Time}{$key}\n";
}
print "end: dump $key\n";
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub smooth{
   for $Id(sort keys %{$tcxdb{Activity}}){
      print "Id=$Id\n";
      #get start and end time
      my $t_start=1e20;
      my $t_end=-1;
      for $Time(keys %{$tcxdb{Activity}{$Id}{Trackpoint}}){
         $t_start=$Time if($t_start>$Time);
         $t_end=$Time if($t_end<$Time);
      }
      print "t_start=$t_start\n";
      print "t_end=$t_end\n";
      print "diff=",$t_end-$t_start,"\n";
      for my $key(qw(AltitudeMeters Speed DistanceMeters RunCadence HeartRateBpm)){

	 #mydump($Id,$key);
         #------------------------------------------------------------------
	 #make sure first trackpoint has a value for this key
	 $Time=$t_start;
         while(!defined $tcxdb{Activity}{$Id}{Trackpoint}{$Time}{$key}){$Time++;}
	 my $v_start=$tcxdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 #print "key=$key, Time=$Time, v_start=$v_start\n";
	 while(--$Time ge $t_start){
	    print "start: setting $key=$v_start for Time=$Time\n";
	    $tcxdb{Activity}{$Id}{Trackpoint}{$Time}{$key}=$v_start;
	 }
	 #mydump($Id,$key);

         #------------------------------------------------------------------
	 #make sure last trackpoint has a value for this key
	 $Time=$t_end;
         while(!defined $tcxdb{Activity}{$Id}{Trackpoint}{$Time}{$key}){$Time--;}
	 my $v_end=$tcxdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 #print "key=$key, Time=$Time, v_end=$v_end\n";
	 while(++$Time le $t_end){
	    print "end: setting $key=$v_end for Time=$Time\n";
	    $tcxdb{Activity}{$Id}{Trackpoint}{$Time}{$key}=$v_end;
	 }
	 #mydump($Id,$key);
         
         #------------------------------------------------------------------
	 my $t_missing="";
	 $Time=$t_start;
         while($Time<=$t_end){
            if(!defined $tcxdb{Activity}{$Id}{Trackpoint}{$Time}{$key}){
	       $t_missing=$Time;
	       $Time++;
               while(!defined $tcxdb{Activity}{$Id}{Trackpoint}{$Time}{$key}){
	          $Time++;
               }
               $v_start=$tcxdb{Activity}{$Id}{Trackpoint}{$t_missing-1}{$key};
               $v_end=$tcxdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	       #print "key=$key, t_missing=$t_missing, Time=$Time, v_start=$v_start, v_end=$v_end\n";
	      for(my $t=0;$t<$Time-$t_missing;$t++){
	         my $v=$v_start+($v_end-$v_start)/($Time-$t_missing+1)*($t+1);
                 $tcxdb{Activity}{$Id}{Trackpoint}{$t_missing+$t}{$key}=$v;
	      }
	    }
	    else{
	       $Time++;
	    }
            #print "Time=$Time\n" if($Time eq $t_start);
            #print "Time=$Time\n" if($Time eq $t_end);
         }
	 #mydump($Id,$key);
      }
   }
   #print Dumper(%{$tcxdb{Activity}});
   #for $Id(keys %{$tcxdb{Activity}{$Id}{Trackpoint}{$Time}{DistanceMeters}=$DistanceMeters;
}
         
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub populate_hrmdb{
for $Id(sort keys %{$tcxdb{Activity}}){
   print "populate_hrmdb: Id=$Id\n";
   #mydump($Id,"HeartRateBpm");
   for $Time(sort keys %{$tcxdb{Activity}{$Id}{Trackpoint}}){
      my $hr=int 0.5+$tcxdb{Activity}{$Id}{Trackpoint}{$Time}{HeartRateBpm};
      my $speed=int 0.5+36*$tcxdb{Activity}{$Id}{Trackpoint}{$Time}{Speed};
      my $cadence=int 0.5+$tcxdb{Activity}{$Id}{Trackpoint}{$Time}{RunCadence};
      my $altitude=int 0.5+$tcxdb{Activity}{$Id}{Trackpoint}{$Time}{AltitudeMeters};
      push @{$hrmdb{HRData}},"$hr\t$speed\t$cadence\t$altitude"; 
   }
}
}

#---------------------------------------------------------------------------
#tbd - using xml::parser is not optimal for generating xml file, because
#you need to manually get all the values and output as xml.
#---------------------------------------------------------------------------
sub gen_tcxfile{
open TCX,">$tcxfileout" or die "cannot create $tcxfileout";
print TCX<<EOT
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<TrainingCenterDatabase
xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.garmin.com/xmlschemas/ActivityExtension/v2
http://www.garmin.com/xmlschemas/ActivityExtensionv2.xsd
http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2
http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd">
EOT
;
print TCX "<Activities>\n";
print TCX "</Activities>\n";
print TCX <<EOT;
 <Author xsi:type="Application_t">
    <Name>$tcxdb{Author}{Name}</Name>
    <Build>
      <Version>
        <VersionMajor>$tcxdb{Author}{Build}{Version}{VersionMajor}</VersionMajor>
        <VersionMinor>$tcxdb{Author}{Build}{Version}{VersionMinor}</VersionMinor>
        <BuildMajor>$tcxdb{Author}{Build}{Version}{BuildMajor}</BuildMajor>
        <BuildMinor>$tcxdb{Author}{Build}{Version}{BuildMinor}</BuildMinor>
      </Version>
      <Type>$tcxdb{Author}{Build}{Type}</Type>
      <Time>$tcxdb{Author}{Build}{Time}</Time>
      <Builder>$tcxdb{Author}{Build}{Builder}</Builder>
    </Build>
    <LangID>$tcxdb{Author}{LangID}</LangID>
    <PartNumber>$tcxdb{Author}{PartNumber}</PartNumber>
  </Author>
EOT
;
print TCX "</Author>\n";
print TCX "</TrainingCenterDatabase>\n";
close TCX;
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub gen_hrmfile{
open HRM,">$hrmfile" or die "cannot create $hrmfile";
for my $s(qw(Params)){
   print HRM qq([$s]\n);
   for my $key(sort{$hrmdb{$s}{$a}{order} <=> $hrmdb{$s}{$b}{order}} 
               keys %{$hrmdb{$s}}){
      print HRM qq($key=$hrmdb{$s}{$key}{payload}\n);
   }
   print HRM "\n";
}
for my $s(qw(Note IntTimes ExtraData Summary-123 Summary-TH
             HRZones SwapTimes Trip HRData)){
   print HRM qq([$s]\n);
   for my $l(@{$hrmdb{$s}}){
      print HRM "$l\n";
   }
   print HRM "\n";
}
close HRM;
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub parse_tcxfile{
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
#my ($yy,$mm,$dd,$tt,$rest)=split/-/,$tcxfilein;
#print "yy=$yy, mm=$mm, dd=$dd\n";
#print "premature\n";exit 1;

#---------------------------------------------------------------------------
#parse the tcx file
open TCX,"<$tcxfilein" or die "cannot open $tcxfilein";
print "parsing $tcxfilein...\n";
$parser->parse(*TCX);
close(TCX);

#---------------------------------------------------------------------------
#dump datastructure for debugging
#print Dumper(%tcxdb);

#---------------------------------------------------------------------------
} #sub parse_tcxfile


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
      $StartTime=str2time($atts{StartTime});
   }
   #print "start_element: el=$el\n";
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub end_element{
   my ($p, $el) = @_;
   #print "end_element: el=$el\n";
   if($el eq "Activity"){
      #print "Activity completed: Sport=$Sport, Id=$Id\n";
      $tcxdb{Activity}{$Id}{Sport}=$Sport;
   }
   elsif($el eq "Lap"){
      #print "Lap completed: TotalTimeSeconds=$TotalTimeSeconds\n";
      $tcxdb{Activity}{$Id}{Lap}{$StartTime}{TotalTimeSeconds}=$TotalTimeSeconds;
   }
   elsif($el eq "Trackpoint"){
      #print "Trackpoint completed: Time=$Time\n";
      $Time=str2time($Time);
      if(!$Time){
         print "Warning: error converting Time - skipping\n";
	 return;
      }
      if("$DistanceMeters"){
         $tcxdb{Activity}{$Id}{Trackpoint}{$Time}{DistanceMeters}=$DistanceMeters;
         $DistanceMeters="";
      }
      if("$Speed"){
         $tcxdb{Activity}{$Id}{Trackpoint}{$Time}{Speed}=$Speed;
         $Speed="";
      }
      if("$RunCadence"){
         $tcxdb{Activity}{$Id}{Trackpoint}{$Time}{RunCadence}=$RunCadence;
         $RunCadence="";
      }
      if("$HeartRateBpm"){
         $tcxdb{Activity}{$Id}{Trackpoint}{$Time}{HeartRateBpm}=$HeartRateBpm;
         $HeartRateBpm="";
      }
      if("$AltitudeMeters"){
         $tcxdb{Activity}{$Id}{Trackpoint}{$Time}{AltitudeMeters}=$AltitudeMeters;
         $AltitudeMeters="";
      }
   }
   elsif($el eq "Name"){
      $Name=$currval;
   }
   elsif($el eq "Type"){
      $Type=$currval;
   }
   elsif($el eq "Time"){
      $Time=$currval;
   }
   elsif($el eq "Builder"){
      $Builder=$currval;
   }
   elsif($el eq "LangID"){
      $LangID=$currval;
   }
   elsif($el eq "PartNumber"){
      $PartNumber=$currval;
   }
   elsif($el eq "VersionMajor"){
      $VersionMajor=$currval;
   }
   elsif($el eq "VersionMinor"){
      $VersionMinor=$currval;
   }
   elsif($el eq "BuildMajor"){
      $BuildMajor=$currval;
   }
   elsif($el eq "BuildMinor"){
      $BuildMinor=$currval;
   }
   elsif($el eq "Version"){
      $tcxdb{Author}{Build}{Version}{VersionMajor}=$VersionMajor;
      $tcxdb{Author}{Build}{Version}{VersionMinor}=$VersionMinor;
      $tcxdb{Author}{Build}{Version}{BuildMajor}=$BuildMajor;
      $tcxdb{Author}{Build}{Version}{BuildMinor}=$BuildMinor;
   }
   elsif($el eq "Build"){
      $tcxdb{Author}{Build}{Type}=$Type;
      $tcxdb{Author}{Build}{Time}=$Time;
      $tcxdb{Author}{Build}{Builder}=$Builder;
   }
   elsif($el eq "Author"){
      $tcxdb{Author}{Name}=$Name;
      $tcxdb{Author}{LangID}=$LangID;
      $tcxdb{Author}{PartNumber}=$PartNumber;
   }
   elsif($el eq "Id"){
      $Id=$currval;
   }
   elsif($el eq "Id"){
      $Id=$currval;
   }
   elsif($el eq "Id"){
      $Id=$currval;
   }
   elsif($el eq "Time"){
      $Time=str2time($currval);
   }
   elsif($el eq "HeartRateBpm"){
      $HeartRateBpm=$Value;
   }
   elsif($el eq "Value"){
      $Value=$currval;
   }
   elsif($el eq "Speed"){
      $Speed=$currval;
   }
   elsif($el eq "RunCadence"){
      $RunCadence=$currval;
   }
   elsif($el eq "DistanceMeters"){
      $DistanceMeters=$currval;
   }
   elsif($el eq "AltitudeMeters"){
      $AltitudeMeters=$currval;
   }
   elsif($el eq "TotalTimeSeconds"){
      $TotalTimeSeconds=$currval;
   }
}

#---------------------------------------------------------------------------
#main code starts here

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
#populate from cfgdb
@{$hrmdb{HRZones}}=@{$$rcfgdb{USER}{HRZONES}};
@{$hrmdb{Trip}}=@{$$rcfgdb{USER}{TRIP}};
@{$hrmdb{Note}}=("This section is not used");

#---------------------------------------------------------------------------
parse_tcxfile();

#---------------------------------------------------------------------------
#gen_tcxfile();

#---------------------------------------------------------------------------
smooth();

#---------------------------------------------------------------------------
populate_hrmdb();

#---------------------------------------------------------------------------
gen_hrmfile();
