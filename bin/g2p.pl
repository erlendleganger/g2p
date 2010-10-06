#---------------------------------------------------------------------------
use strict;
use XML::Parser::Expat;
use HTTP::Date;
use Data::Dumper;
use POSIX qw{strftime}; 
use Log::Log4perl;
$Data::Dumper::Indent = 1;
my %db;
my $currval;
my $l="-"x72 ."\n";
my $log;
my $SportIdRunning=1;
my $SportIdCycling=2;
my $SModeRunning="111000100";
my $SModeCycling="111111100";

#---------------------------------------------------------------------------
my $timeoffsetfit=str2time("1989-12-31T00:00:00Z");
my %exdb;
my %hrmdb;
my %pddb;
my $rcfgdb;
my $inTrack;
my $AltitudeMeters;
my $BuildMajor;
my $BuildMinor;
my $Builder;
my $DistanceMeters;
my $LapDistanceMeters;
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
$hrmdb{Params}{Date}{order}=$order++;
#$hrmdb{Params}{Date}{payload}="20100712";
$hrmdb{Params}{StartTime}{order}=$order++;
#$hrmdb{Params}{StartTime}{payload}="19:05:09.0";
$hrmdb{Params}{Length}{order}=$order++;
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

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub fmt_time{
   my $t=shift;
   "$t [",strftime("\%Y-\%m-\%d \%H:\%M:\%S", localtime($t)),"]";
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub mydump{
my $id=shift;
my $key=shift;
print "start: dump $key\n";
for $Time(sort keys %{$exdb{Activity}{$id}{Trackpoint}}){
   print "Time=$Time, $key=$exdb{Activity}{$id}{Trackpoint}{$Time}{$key}\n";
}
print "end: dump $key\n";
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub smooth_exdb{
my $key;
my $last_val;
   for $Id(sort keys %{$exdb{Activity}}){
      #get start and end time
      my $t_start=1e20;
      my $t_end=-1;
      for $Time(keys %{$exdb{Activity}{$Id}{Trackpoint}}){
         $t_start=$Time if($t_start>$Time);
         $t_end=$Time if($t_end<$Time);
      }
      #for my $key(qw(AltitudeMeters Speed RunCadence HeartRateBpm Power)){
      #for my $key(qw(AltitudeMeters Speed HeartRateBpm Power)){
      #for my $key(qw(HeartRateBpm)){

      #---------------------------------------------------------------------
      $key="HeartRateBpm";
      $Time=$t_start;
      $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
      $log->debug("smooth: key=$key, t_start=",
         fmt_time($t_start),", last_val=$last_val\n");
      while($Time<=$t_end){
	 my $cur_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 if($cur_val<50){
            $log->debug("smooth: key=$key, Time=",fmt_time($Time),
	       ", old value=$cur_val, new value=$last_val\n");
            $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}=$last_val;
	 }
         $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 $Time++;
      }

      #---------------------------------------------------------------------
      $key="Speed";
      $Time=$t_start;
      $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
      $log->debug("smooth: key=$key, t_start=",
         fmt_time($t_start),", last_val=$last_val\n");
      while($Time<=$t_end){
	 my $cur_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
         #$log->debug("smooth: key=$key, Time=",fmt_time($Time),", value=",
         #   $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key},"\n");
	 if($cur_val>2*$last_val && $last_val>1.0){
            $log->debug("smooth: key=$key, Time=",fmt_time($Time),
	       ", old value=$cur_val, new value=$last_val\n");
            $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}=$last_val;
	 }
         $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 $Time++;
      }

      #---------------------------------------------------------------------
      $key="AltitudeMeters";
      $Time=$t_start;
      $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
      $log->debug("smooth: key=$key, t_start=",
         fmt_time($t_start),", last_val=$last_val\n");
      while($Time<=$t_end){
	 my $cur_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
         #$log->debug("smooth: key=$key, Time=",fmt_time($Time),", value=",
         #   $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key},"\n");
	 if($cur_val>($last_val+10) || $cur_val<($last_val-10)){
            $log->debug("smooth: key=$key, Time=",fmt_time($Time),
	       ", old value=$cur_val, new value=$last_val\n");
            $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}=$last_val;
	 }
         $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 $Time++;
      }

      #---------------------------------------------------------------------
      $key="RunCadence";
      $Time=$t_start;
      $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
      $log->debug("smooth: key=$key, t_start=",
         fmt_time($t_start),", last_val=$last_val\n");
      while($Time<=$t_end){
	 my $cur_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 if($cur_val>($last_val*1.10)){
            $log->debug("smooth: key=$key, Time=",fmt_time($Time),
	       ", old value=$cur_val, new value=$last_val\n");
            $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}=$last_val;
	 }
         $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}=($cur_val+$last_val)/2;
         $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 $Time++;
      }

   }
}
         

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub extrapolate_exdb{
   for $Id(sort keys %{$exdb{Activity}}){
      #get start and end time
      my $t_start=1e20;
      my $t_end=-1;
      for $Time(keys %{$exdb{Activity}{$Id}{Trackpoint}}){
         $t_start=$Time if($t_start>$Time);
         $t_end=$Time if($t_end<$Time);
      }

      $log->debug("expol: Id=$Id\n");
      $log->debug("expol: t_start=",fmt_time($t_start),"\n");
      $log->debug("expol: t_end=",fmt_time($t_end),"\n");
      $log->debug("expol: diff=",$t_end-$t_start,"\n");
      for my $key(qw(AltitudeMeters Speed DistanceMeters RunCadence HeartRateBpm)){

         #------------------------------------------------------------------
	 $log->debug("expol: current key=$key");

         #------------------------------------------------------------------
	 #make sure first trackpoint has a value for this key
	 $Time=$t_start;
         while($Time < $t_end && 
	    !defined $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}){$Time++;}
         if($Time==$t_end){
	    #no values found, skip to next key
	    $log->debug("expol: no values found for key=$key");
	    next;
	 }
	 my $v_start=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 $log->debug("Time=",fmt_time($Time),", v_start=$v_start\n");
	 while(--$Time ge $t_start){
	    $log->debug("expol: start - setting $key=$v_start for Time=",
	    fmt_time($Time),"\n");
	    $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}=$v_start;
	 }

         #------------------------------------------------------------------
	 #make sure last trackpoint has a value for this key
	 $Time=$t_end;
         while(!defined $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}){$Time--;}
	 my $v_end=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 $log->debug("expol: Time=",fmt_time($Time),
	    ", v_end=$v_end\n");
	 while(++$Time le $t_end){
	    $log->debug("expol: end - setting $key=$v_end for Time=",
	       fmt_time($Time),"\n");
	    $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}=$v_end;
	 }
         
         #------------------------------------------------------------------
	 my $t_missing="";
	 $Time=$t_start;
         while($Time<=$t_end){
            if(!defined $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}){
	       $t_missing=$Time;
	       $Time++;
               while(!defined $exdb{Activity}{$Id}{Trackpoint}{$Time}{$key}){
	          $Time++;
	          $log->debug("expol: hunting, Time=$Time",fmt_time($Time));
               }
               $v_start=$exdb{Activity}{$Id}{Trackpoint}{$t_missing-1}{$key};
               $v_end=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	       $log->debug("expol: t_missing=",
	          fmt_time($t_missing),", Time=",fmt_time($Time),
	          " , v_start=$v_start, v_end=$v_end\n");
	      for(my $t=0;$t<$Time-$t_missing;$t++){
	         my $v=$v_start+($v_end-$v_start)/($Time-$t_missing+1)*($t+1);
	         $log->debug("expol: t=$t, v=$v");
                 $exdb{Activity}{$Id}{Trackpoint}{$t_missing+$t}{$key}=$v;
	      }
	    }
	    else{
	       $Time++;
	       $log->debug("expol: ok - Time=$Time",fmt_time($Time));
	    }
         }
      }
   }
}
         
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub populate_hrmdb{

#---------------------------------------------------------------------------
#populate from cfgdb
@{$hrmdb{HRZones}}=@{$$rcfgdb{USER}{HRZONES}};
@{$hrmdb{Trip}}=@{$$rcfgdb{USER}{TRIP}};
for $Id(sort keys %{$exdb{Activity}}){
   #print "populate_hrmdb: Id=$Id\n";

   #------------------------------------------------------------------------
   #populate the HRData section of the hrm structure
   for $Time(sort keys %{$exdb{Activity}{$Id}{Trackpoint}}){
      my $hr=int 0.5+$exdb{Activity}{$Id}{Trackpoint}{$Time}{HeartRateBpm};
      my $speed=int 0.5+36*$exdb{Activity}{$Id}{Trackpoint}{$Time}{Speed};
      my $cadence=int 0.5+$exdb{Activity}{$Id}{Trackpoint}{$Time}{RunCadence};
      my $altitude=int 0.5+$exdb{Activity}{$Id}{Trackpoint}{$Time}{AltitudeMeters};
      my $power=int 0.5+$exdb{Activity}{$Id}{Trackpoint}{$Time}{Power};
      #print "$Time,$hr,$speed,$cadence,$altitude\n";
      push @{$hrmdb{HRData}},[$hr,$speed,$cadence,$altitude,$power]; 
   }

   #------------------------------------------------------------------------
   #populate IntTimes section and some of the Param section in the hrm structure
   my $totaltime;
   my $totaldistance;
   my $firstlapstarttime;
   for $Time(sort keys %{$exdb{Activity}{$Id}{Lap}}){
      $firstlapstarttime=$Time if(!$firstlapstarttime);
      my $laptime=$exdb{Activity}{$Id}{Lap}{$Time}{TotalTimeSeconds};
      my $lapdistance=$exdb{Activity}{$Id}{Lap}{$Time}{DistanceMeters};
      $totaltime+=$laptime;
      $totaldistance+=$lapdistance;
      my $laptimestr=strftime("\%H:\%M:\%S.0", gmtime($totaltime));
      $log->debug("lap start: ",fmt_time($Time),
         ", laptimestr: $laptimestr, lap time: $laptime sec [",
          strftime("\%M:\%S",localtime($laptime)),"]\n");
      push @{$hrmdb{IntTimes}},[$laptimestr,0,0,0,0];
      push @{$hrmdb{IntTimes}},[0,0,0,0,0];
      push @{$hrmdb{IntTimes}},[0,0,0,0,0];
      push @{$hrmdb{IntTimes}},[0,0,0,0,0];
      push @{$hrmdb{IntTimes}},[0,0,0,0,0];
   }
   $hrmdb{Params}{Length}{payload}=strftime("\%H:\%M:\%S.0", gmtime($totaltime));
   $hrmdb{Params}{Date}{payload}=strftime("\%Y\%m\%d", localtime($firstlapstarttime));
   $hrmdb{Params}{StartTime}{payload}=strftime("\%H:\%M:\%S.0", localtime($firstlapstarttime));
   $hrmdb{SPORTID}=$exdb{Activity}{$Id}{SportId};
   $hrmdb{Params}{SMode}{payload}=$exdb{Activity}{$Id}{SMode};
   $hrmdb{DISTANCE}=$totaldistance;
   $hrmdb{STARTTIME}=$firstlapstarttime;
   $hrmdb{TOTALTIME}=$totaltime;
   #$hrmdb{HRMFILE}=strftime("\%g\%m\%d01.hrm", localtime($firstlapstarttime));
   $hrmdb{PDDFILE}=strftime("\%Y\%m\%d.pdd", localtime($firstlapstarttime));
   $hrmdb{DTG0}=strftime("\%Y\%m\%d", localtime($firstlapstarttime));
   $hrmdb{DTG1}=strftime("\%Y-\%m-\%d", localtime($firstlapstarttime));
   $hrmdb{DTG2}=strftime("\%Y-\%m-\%d \%H:\%M:\%S", localtime($firstlapstarttime));
}
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub user_interaction{
print  "$l";
print  "Date....: ",strftime("\%Y-\%m-\%d",localtime($hrmdb{STARTTIME})),"\n";
print  "Start...: ",strftime("\%H:\%M",localtime($hrmdb{STARTTIME})),"\n";
print  "Duration: $hrmdb{Params}{Length}{payload}\n";
printf "Distance: %.1fkm\n", $hrmdb{DISTANCE}/1000.0;
my $lapnum;
my %lapdata;
my $lapstr;
for $Id(sort keys %{$exdb{Activity}}){
   print  "$l";
   for $StartTime(sort keys %{$exdb{Activity}{$Id}{Lap}}){
      $lapnum++;
      $lapstr=sprintf("%d: ",$lapnum);
      my $seconds=$exdb{Activity}{$Id}{Lap}{$StartTime}{TotalTimeSeconds};
      if($seconds>60*60){
         $lapstr.=strftime("\%H:\%M:\%S",gmtime($seconds));
      }
      else{
         $lapstr.=strftime("\%M:\%S",gmtime($seconds));
      }
      my $distkm=$exdb{Activity}{$Id}{Lap}{$StartTime}{DistanceMeters}/1000.0;
      $lapstr.=sprintf(", %.1fkm, ",$distkm);
      if($exdb{Activity}{$Id}{SportId} eq $SportIdRunning){
         $lapstr.=strftime("\%M:\%Smin/km",gmtime($seconds/$distkm));
      }
      else{
         $lapstr.=sprintf("%.1fkm/t",$distkm/($seconds/3600.0));
      }
      $lapdata{$lapnum}=$lapstr;
      print "$lapstr\n";
   }
}
#print  "Exercise: "; $hrmdb{EXERCISE}=<STDIN>; chomp $hrmdb{EXERCISE};

#---------------------------------------------------------------------------
print  "${l}Add this session to Polar ProTrainer? [y, n] ";
my $answer=<STDIN>;chomp $answer;
if($answer eq "y"){
   print  "Comment.: "; 
   my $note=<STDIN>; chomp $note;
   print "Include laps? [n; all; 0,2,3]: ";
   $answer=<STDIN>;chomp $answer;
   if($answer ne "n"){
      if($answer eq "all"){
         $note.=join "; ", map{$lapdata{$_}} sort{$a<=>$b}keys %lapdata;
      }
   }
   #print "note=$note\n";
   #push @{$hrmdb{Note}},[$note];
   $hrmdb{NOTE}=$note;
   push @{$hrmdb{Note}},[$hrmdb{NOTE}];
   return 1;
}
else{
   print "Skipping session...\n";
   return "";
}
}

#---------------------------------------------------------------------------
#tbd - using xml::parser is not optimal for generating xml file, because
#you need to manually get all the values and output as xml.
#---------------------------------------------------------------------------
sub gen_tcxfile{

my $tcxfileout="/tmp/out.tcx";

#---------------------------------------------------------------------------
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
    <Name>$exdb{Author}{Name}</Name>
    <Build>
      <Version>
        <VersionMajor>$exdb{Author}{Build}{Version}{VersionMajor}</VersionMajor>
        <VersionMinor>$exdb{Author}{Build}{Version}{VersionMinor}</VersionMinor>
        <BuildMajor>$exdb{Author}{Build}{Version}{BuildMajor}</BuildMajor>
        <BuildMinor>$exdb{Author}{Build}{Version}{BuildMinor}</BuildMinor>
      </Version>
      <Type>$exdb{Author}{Build}{Type}</Type>
      <Time>$exdb{Author}{Build}{Time}</Time>
      <Builder>$exdb{Author}{Build}{Builder}</Builder>
    </Build>
    <LangID>$exdb{Author}{LangID}</LangID>
    <PartNumber>$exdb{Author}{PartNumber}</PartNumber>
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
#---------------------------------------------------------------------------

my $dtg=strftime("\%g\%m\%d", localtime($hrmdb{STARTTIME}));
my $hrmfile="${dtg}01.hrm";
my $i=2;
while(-f "$ENV{POLARDIR}/$hrmfile"){
   $hrmfile=sprintf "$dtg%02d.hrm", $i++;
}
#print "hrmfile=$hrmfile\n";
$hrmdb{HRMFILE}=$hrmfile;
open HRM,">$ENV{POLARDIR}/$hrmfile" or die "cannot create $hrmfile";
print "creating $hrmfile...\n";
for my $s(qw(Params)){
   print HRM qq([$s]\n);
   for my $key(sort{$hrmdb{$s}{$a}{order} <=> $hrmdb{$s}{$b}{order}} keys %{$hrmdb{$s}}){
      print HRM qq($key=$hrmdb{$s}{$key}{payload}\n);
   }
   print HRM "\n";
}
for my $s(qw(Note IntTimes ExtraData Summary-123 Summary-TH
             HRZones SwapTimes Trip HRData)){
   print HRM qq([$s]\n);
   for my $aref(@{$hrmdb{$s}}){
      my $l=join "\t",@$aref;
      print HRM "$l\n";
   }
   print HRM "\n";
}

close HRM;
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub gen_pddfile{
my $pddfile="$hrmdb{PDDFILE}";
open PDD,">$ENV{POLARDIR}/$pddfile" or die "cannot create $pddfile";
print "updating $pddfile...\n";
for my $s(qw(DayInfo), sort @{$pddb{EXERCISEINFOLIST}}){
   print PDD qq([$s]\n);
   for my $aref(@{$pddb{$s}}){
      my $l=join "\t",@$aref;
      print PDD "$l\n";
   }
   print PDD "\n";
}
close PDD;
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub populate_pddb{
my $pddfile="$ENV{POLARDIR}/$hrmdb{PDDFILE}";
if(-f $pddfile){
   open PDD,"<$pddfile" or die "cannot open $pddfile";
   print "reading existing $hrmdb{PDDFILE}...\n";
   my $section;
   while(<PDD>){
      chomp;
      if(m/\[(.*)\]/){
         $section=$1;
         push @{$pddb{EXERCISEINFOLIST}},$section if($section=~m/ExerciseInfo/);
         $pddb{EXERCISECOUNT}++ if($section=~m/ExerciseInfo/);
      }
      else{
         push @{$pddb{$section}},[split /\t/,$_] if ($section);
      }
   }
   close PDD;
}

my $i=1;
my $e="ExerciseInfo$i";
while(defined $pddb{$e}){
   $e="ExerciseInfo". ++$i;
}
push @{$pddb{EXERCISEINFOLIST}},$e;
$pddb{EXERCISECOUNT}++;
#print "count=$pddb{EXERCISECOUNT}\n";
push @{$pddb{$e}},[101,1,24,6,12,512],
[0,0,0,int($hrmdb{DISTANCE}),
int($hrmdb{STARTTIME}-str2time(strftime("\%Y-\%m-\%dT00:00:00", localtime($hrmdb{STARTTIME})))),
int($hrmdb{TOTALTIME})],
[$hrmdb{SPORTID},77,0,2,0,364],
[int($hrmdb{DISTANCE}),0,0,0,0,55],
[2,0,0,0,0,0],
[0,0,0,0,56,174],
[2540,0,0,0,0,10007],
[0,0,0,0,1,2],
[0,0,0,0,1,0],
[131,163,100,156,75,81],
[91,117,0,0,0,0],
[0,0,0,0,0,45],
[473,0,6050,0,0,364],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[$hrmdb{EXERCISE}],
[$hrmdb{NOTE}],
[$hrmdb{HRMFILE}],
[],
[],
[],
[],
[],
[],
[],
;
if(!defined $pddb{DayInfo}){
push @{$pddb{DayInfo}},[100,1,7,6,1,512],
[$hrmdb{DTG0},$pddb{EXERCISECOUNT},0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[0,0,0,0,0,0],
[],
;
#day note in empty line above
}
else{
   ${$pddb{DayInfo}}[1][1]=$pddb{EXERCISECOUNT};
}
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub parse_fitcsvfile{
my $fitcsvfile="$ENV{FITCSVDIR}/$ENV{INFILEBASE}.csv";
$Id="fit";
open CSV, "<$fitcsvfile" or die "cannot open $fitcsvfile";
$exdb{Activity}{$Id}{SportId}=$SportIdCycling;
$exdb{Activity}{$Id}{SMode}=$SModeCycling;
while(<CSV>){
   my @l;
   if(m/Data,\d+,lap,/){
      @l=split /,/;
      #print strftime("\%H:\%M:\%S", localtime($l[4])),",";
      $Time=$l[4]+$timeoffsetfit;
      $StartTime=$l[7]+$timeoffsetfit;
      $TotalTimeSeconds=$l[22];
      $LapDistanceMeters=$l[28];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{TotalTimeSeconds}=$TotalTimeSeconds;
      $exdb{Activity}{$Id}{Lap}{$StartTime}{DistanceMeters}=$LapDistanceMeters;
   }
   elsif(m/Data,\d+,record,/){
      @l=split /,/;
      #print strftime("\%H:\%M:\%S", localtime($l[4])),",";
      $Time=$l[4]+$timeoffsetfit;
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{DistanceMeters}=$l[13];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{AltitudeMeters}=$l[16];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{Speed}=$l[19];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{Power}=$l[22];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{HeartRateBpm}=$l[25];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{RunCadence}=$l[28];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{Temperature}=$l[31];
   }
}
close CSV;
#for(qw(AltitudeMeters Speed RunCadence HeartRateBpm)){mydump($Id,$_); }
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
#parse the tcx file
my $tcxfilein="$ENV{INFILE}";
open TCX,"<$tcxfilein" or die "cannot open $tcxfilein";
#print "parsing $tcxfilein...\n";
$parser->parse(*TCX);
close(TCX);

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
   elsif($el eq "Track"){
      $inTrack="true";
   }
   #print "start_element: el=$el\n";
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub end_element{
   my ($p, $el) = @_;
   #print "end_element: el=$el\n";
   if($el eq "Activity"){
      $log->debug("Activity completed: Sport=$Sport, Id=$Id\n");
      $exdb{Activity}{$Id}{Sport}=$Sport;
      if($Sport eq "Running"){
         $exdb{Activity}{$Id}{SportId}=$SportIdRunning;
         $exdb{Activity}{$Id}{SMode}=$SModeRunning;
      }
      else{
         $log->fatal("Unknown sport!\n");
	 exit 1;
      }
   }
   elsif($el eq "Lap"){
      #print "Lap completed: TotalTimeSeconds=$TotalTimeSeconds\n";
      $exdb{Activity}{$Id}{Lap}{$StartTime}{TotalTimeSeconds}=$TotalTimeSeconds;
      $exdb{Activity}{$Id}{Lap}{$StartTime}{DistanceMeters}=$LapDistanceMeters;
   }
   elsif($el eq "Trackpoint"){
      #print "Trackpoint completed: Time=$Time\n";
      $Time=str2time($Time);
      if(!$Time){
         print "Warning: error converting Time - skipping\n";
	 return;
      }
      if("$DistanceMeters"){
         $exdb{Activity}{$Id}{Trackpoint}{$Time}{DistanceMeters}=$DistanceMeters;
         $DistanceMeters="";
      }
      if("$Speed"){
         $exdb{Activity}{$Id}{Trackpoint}{$Time}{Speed}=$Speed;
         $Speed="";
      }
      if("$RunCadence"){
         $exdb{Activity}{$Id}{Trackpoint}{$Time}{RunCadence}=$RunCadence;
         $RunCadence="";
      }
      if("$HeartRateBpm"){
         $exdb{Activity}{$Id}{Trackpoint}{$Time}{HeartRateBpm}=$HeartRateBpm;
         $HeartRateBpm="";
      }
      if("$AltitudeMeters"){
         $exdb{Activity}{$Id}{Trackpoint}{$Time}{AltitudeMeters}=$AltitudeMeters;
         $AltitudeMeters="";
      }
   }
   elsif($el eq "Track"){
      $inTrack="";
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
      $exdb{Author}{Build}{Version}{VersionMajor}=$VersionMajor;
      $exdb{Author}{Build}{Version}{VersionMinor}=$VersionMinor;
      $exdb{Author}{Build}{Version}{BuildMajor}=$BuildMajor;
      $exdb{Author}{Build}{Version}{BuildMinor}=$BuildMinor;
   }
   elsif($el eq "Build"){
      $exdb{Author}{Build}{Type}=$Type;
      $exdb{Author}{Build}{Time}=$Time;
      $exdb{Author}{Build}{Builder}=$Builder;
   }
   elsif($el eq "Author"){
      $exdb{Author}{Name}=$Name;
      $exdb{Author}{LangID}=$LangID;
      $exdb{Author}{PartNumber}=$PartNumber;
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
      if($inTrack){
         $DistanceMeters=$currval;
      }
      else{
         $LapDistanceMeters=$currval;
      }
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
#set up the logger
my $conf=q(
#level: one of DEBUG, INFO, WARN, ERROR, FATAL:
log4perl.rootLogger              = DEBUG, myLog
log4perl.appender.myLog          = Log::Log4perl::Appender::File
log4perl.appender.myLog.filename = /tmp/g2p.log
log4perl.appender.myLog.mode     = clobber
log4perl.appender.myLog.layout   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.myLog.layout.ConversionPattern = [%d] [%p] [%L] %m%n
);
Log::Log4perl::init(\$conf);
$log = Log::Log4perl->get_logger;

#---------------------------------------------------------------------------
#load the initialisation file
my $cfgfile="$ENV{PLCFGFILE}";
if(-f $cfgfile){
   $log->debug("loading $cfgfile...\n");
   require $cfgfile;
}
else{
   $log->error("cannot find $cfgfile\n");
   die "cannot find $cfgfile";
}
 
#---------------------------------------------------------------------------
#get the cfg db
if(defined &get_cfgdb){
   $rcfgdb=get_cfgdb();
}
else{
   $log->error("cannot get cfgdb\n");
   die "cannot get cfgdb";
}
#print Dumper(%$rcfgdb);
#print "$$rcfgdb{USER}{NAME}\n";
#print "premature\n";exit 1;

#---------------------------------------------------------------------------
#check environment
die "ID is not set" if(!$ENV{ID});
die "INFILE is not set" if(!$ENV{INFILE});
die "INFILEBASE is not set" if(!$ENV{INFILEBASE});
$log->trace("ID=$ENV{ID}\n");
$log->trace("INFILE=$ENV{INFILE}\n");
$log->trace("INFILEBASE=$ENV{INFILEBASE}\n");

#---------------------------------------------------------------------------
my $mode=$ENV{ID};
if($mode eq "fr310xt"){

   #------------------------------------------------------------------------
   parse_tcxfile();

   #------------------------------------------------------------------------
   #gen_tcxfile();

   #------------------------------------------------------------------------
   extrapolate_exdb();

   #------------------------------------------------------------------------
   populate_hrmdb();
   if(user_interaction()){
      gen_hrmfile();
      populate_pddb();
      gen_pddfile();
   }

}

#---------------------------------------------------------------------------
elsif($mode eq "e500"){
   parse_fitcsvfile();
   #extrapolate_exdb();

   #------------------------------------------------------------------------
   extrapolate_exdb();
   smooth_exdb();
   populate_hrmdb();
   if(user_interaction()){
      gen_hrmfile();
      populate_pddb();
      gen_pddfile();
   }
}

#---------------------------------------------------------------------------
elsif($mode eq "tacx"){
   print "mode $mode not yet supported\n";
   print "input file: $ENV{INFILE}\n";
}
