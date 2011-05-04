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
my $SportIdTreadmill=8;
my $SportIdCycling=2;
my $SportIdCyclotrainer=7;
my $SModeRunning="111000100";
my $SModeCycling="111111100";

#---------------------------------------------------------------------------
my $timeoffsetfit=str2time("1989-12-31T00:00:00Z");
my %exdb;
my %hrmdb;
my %pddb;
my $rcfgdb;
my $inTrack;
my $hasGPS;;
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
      $log->debug("smooth: id=$Id, t_start=",fmt_time($t_start),", t_end=",fmt_time($t_end));

      #---------------------------------------------------------------------
      #smooth out hrm data
      $key="HeartRateBpm";
      $Time=$t_start;
      $last_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
      $log->debug("smooth: key=$key, t_start=",
         fmt_time($t_start),", last_val=$last_val\n");
      while($Time<=$t_end){
	 my $cur_val=$exdb{Activity}{$Id}{Trackpoint}{$Time}{$key};
	 #if missing hrm data (<50bpm), then just set the value to the
	 #previously seen value
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
	       #$log->debug("expol: ok - Time=$Time",fmt_time($Time));
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
      $log->debug("pop_hrmdb: Time=$Time,hr=$hr,speed=$speed,cad=$cadence,alt=$altitude,power=$power\n");
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
   #$hrmdb{HRMFILE}=strftime("\%y\%m\%d01.hrm", localtime($firstlapstarttime));
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
      $lapstr=sprintf("#%d: ",$lapnum);
      my $seconds=$exdb{Activity}{$Id}{Lap}{$StartTime}{TotalTimeSeconds};
      if($seconds>60*60){
         $lapstr.=strftime("\%H:\%M:\%S",gmtime($seconds));
      }
      else{
         $lapstr.=strftime("\%M:\%S",gmtime($seconds));
      }
      my $distkm=$exdb{Activity}{$Id}{Lap}{$StartTime}{DistanceMeters}/1000.0;
      $lapstr.=sprintf(", %.1fkm, ",$distkm);
      if($exdb{Activity}{$Id}{SportId} eq $SportIdRunning or 
        $exdb{Activity}{$Id}{SportId} eq $SportIdTreadmill){
         $lapstr.=strftime("\%M:\%Smin/km",gmtime($seconds/$distkm))
	    if($distkm>0);
      }
      else{
         $lapstr.=sprintf("%.1fkm/t, ",$distkm/($seconds/3600.0));
         $lapstr.=sprintf("avg %dW, ",$exdb{Activity}{$Id}{Lap}{$StartTime}{PowerAvg});
         $lapstr.=sprintf("avg %dbpm, ",$exdb{Activity}{$Id}{Lap}{$StartTime}{HeartAvg});
         $lapstr.=sprintf("avg %drpm ",$exdb{Activity}{$Id}{Lap}{$StartTime}{CadenceAvg});
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
   print "Include laps? [n; all; 1,3,7,...]: ";
   $answer=<STDIN>;chomp $answer;
   if($answer ne "n" and $answer ne ""){
      $note.=" Runder: ";
      if($answer eq "all"){
         $note.=join "; ", map{$lapdata{$_}} sort{$a<=>$b}keys %lapdata;
      }
      else{
         for my $lap(split(",",$answer)){
	    if(0<$lap and $lap<=$lapnum){
               $note.="$lapdata{$lap}; ";
	    }
	    else{
	       print "ignoring illegal lap: $lap\n";
	    }
	 }
      }
   }
   $hrmdb{NOTE}=$note; #for the pdd file
   #push @{$hrmdb{Note}},[$note]; #for the hrm file
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

my $dtg=strftime("\%y\%m\%d", localtime($hrmdb{STARTTIME}));
#$log->debug("gen_hrmfile: hrmdb{STARTTIME}=$hrmdb{STARTTIME}, localtime(.)=", localtime($hrmdb{STARTTIME}));
$log->debug("gen_hrmfile: dtg=$dtg");
my $hrmfile="${dtg}01.hrm";
my $i=2;
while(-f "$ENV{POLARDIR}/$hrmfile"){
   $hrmfile=sprintf "$dtg%02d.hrm", $i++;
}
$log->debug("gen_hrmfile: hrmfile=$hrmfile");
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
for my $s(qw(DayInfo), 
            @{$pddb{EXERCISEINFOLIST}},
            @{$pddb{EXEPLANINFOLIST}}){
   print PDD qq([$s]\n);
   $log->debug("gen_pddfile: section=$s");
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
      #---------------------------------------------------------------------
      #search for [DayInfo], [ExerciseInfo1], [ExePlanInfo1] etc
      if(m/\[(.*)\]/){
         $section=$1;
         $log->debug("populate_pddb: section=$section");

         #------------------------------------------------------------------
	 #save the list of ExerciseInfo1,2,3,... sections seen
         if($section=~m/ExerciseInfo/){
            push @{$pddb{EXERCISEINFOLIST}},$section;
            $pddb{EXERCISECOUNT}++;
	 }
         #------------------------------------------------------------------
	 #save the list of ExePlanInfo1,2,3,... sections seen
         if($section=~m/ExePlanInfo/){
            push @{$pddb{EXEPLANINFOLIST}},$section;
            $pddb{EXEPLANCOUNT}++;
	 }
      }
      else{
         #------------------------------------------------------------------
         #not a section line, so push the contents of the line onto the
	 #array of arrays defined for the hash entry for this section
         push @{$pddb{$section}},[split /\t/,$_] if ($section);
      }
   }
   close PDD;
}

#---------------------------------------------------------------------------
#add a new ExerciseInfo section for the exercise added now; must increase
#the section number by one first..
my $i=1;
my $e="ExerciseInfo$i";
while(defined $pddb{$e}){
   $e="ExerciseInfo". ++$i;
}

#---------------------------------------------------------------------------
#add the section here, and then a list of dummy data (for now)
push @{$pddb{EXERCISEINFOLIST}},$e;
$pddb{EXERCISECOUNT}++;
#print "count=$pddb{EXERCISECOUNT}\n";
push @{$pddb{$e}},[101,1,24,6,12,512], #row 0
[0,0,0,int($hrmdb{DISTANCE}),
int($hrmdb{STARTTIME} -
   str2time(strftime("\%Y-\%m-\%dT00:00:00", localtime($hrmdb{STARTTIME})))),
int($hrmdb{TOTALTIME})], #row 1
[$hrmdb{SPORTID},77,0,2,0,364], #row 2
[int($hrmdb{DISTANCE}),0,0,0,0,55], #row 3
[2,0,0,0,0,0], #row 4
[0,0,0,0,56,174], #row 5
[2540,0,0,0,0,10007], #row 6
[0,0,0,0,1,2], #row 7
[0,0,0,0,1,0], #row 8
[131,163,100,156,75,81], #row 9
[91,117,0,0,0,0], #row 10
[0,0,0,0,0,45], #row 11
[473,0,6050,0,0,364], #row 12
[0,0,0,0,0,0], #row 13
[0,0,0,0,0,0], #row 14
[0,0,0,0,0,0], #row 15
[0,0,0,0,0,0], #row 16
[0,0,0,0,0,0], #row 17
[0,0,0,0,0,0], #row 18
[0,0,0,0,0,0], #row 19
[0,0,0,0,0,0], #row 20
[0,0,0,0,0,0], #row 21
[0,0,0,0,0,0], #row 22
[0,0,0,0,0,0], #row 23
[0,0,0,0,0,0], #row 24
[$hrmdb{EXERCISE}], #text row 0
[$hrmdb{NOTE}],     #text row 1
[$hrmdb{HRMFILE}],  #text row 2
[], #text row 3
[], #text row 4
[], #text row 5
[], #text row 6
[], #text row 7
[], #text row 8
[], #text row 9
[], #text row 10
[], #text row 11
[], #text row 12
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

#---------------------------------------------------------------------------
#field position in Data and Record line from csf file
my $iTimeLap;my $iTimeRecord;
my $iStarttimeLap;
my $iTotalttimesecondsLap;
my $iLapdistancemetersLap;
my $iSpeedavgLap; my $iSpeedmaxLap;
my $iPoweravgLap; my $iPowermaxLap;
my $iHeartrateavgLap; my $iHeartratemaxLap;
my $iCadenceavgLap; my $iCadencemaxLap;

my $iDistanceRecord; my $iSpeedRecord; my $iHeartrateRecord; 
my $iCadenceRecord; my $iTemperatureRecord; my $iAltitudeRecord; 
my $iPowerRecord;

#---------------------------------------------------------------------------
#sample entries in the fit csv file:
#Data,6,lap,timestamp,655399331,s,start_time,655398540,,start_position_lat,711209286,semicircles,start_position_long,131472774,semicircles,end_position_lat,711329772,semicircles,end_position_long,132197664,semicircles,total_elapsed_time,790.04,s,total_timer_time,790.04,s,total_distance,6453.85,m,unknown,126.0,,unknown,126.0,,unknown,126.0,,unknown,126.0,,message_index,1,,total_calories,77,kcal,avg_speed,8.169,m/s,max_speed,12.549,m/s,avg_power,142,watts,max_power,371,watts,total_ascent,31,m,total_descent,49,m,event,9,,event_type,1,,avg_heart_rate,120,bpm,max_heart_rate,169,bpm,avg_cadence,82,rpm,max_cadence,239,rpm,intensity,0,,lap_trigger,0,,sport,2,,,,,,,,
#Data,6,lap,timestamp,653066740,s,start_time,653065895,,start_position_lat,711781651,semicircles,start_position_long,131154977,semicircles,end_position_lat,711361999,semicircles,end_position_long,131535685,semicircles,total_elapsed_time,845.34,s,total_timer_time,844.8,s,total_distance,5000.0,m,unknown,126.0,,unknown,126.0,,unknown,126.0,,unknown,126.0,,message_index,0,,total_calories,113,kcal,avg_speed,5.918,m/s,max_speed,15.963,m/s,avg_power,182,watts,max_power,485,watts,total_ascent,96,m,total_descent,61,m,event,9,,event_type,1,,avg_heart_rate,117,bpm,max_heart_rate,146,bpm,avg_cadence,65,rpm,max_cadence,121,rpm,intensity,0,,lap_trigger,2,,sport,2,,,,,,,,

#---------------------------------------------------------------------------
#read until we find the first lap line and record line
seek(CSV,0,0);
my $seenlap;
my $seenrecord;
while(<CSV>){
   if(m/Data,\d+,lap,/ and !$seenlap){
      my @l=split /,/;
      $log->debug("$_");
      $seenlap=1;
      #---------------------------------------------------------------------
      #analyse the record to find the indeces to use
      for(my $i=0;$i<$#l;$i++){
         $log->debug("i=$i, l[$i]=$l[$i]\n");
	 my $field=$l[$i];
	 if($field eq "timestamp"){
	    $iTimeLap=$i+1;
            $log->debug("iTimeLap=$iTimeLap\n");
	 }
	 elsif($field eq "start_position_lat"){
	    $hasGPS=1;
            $log->debug("i start_position_lat=$i\n");
	 }
	 elsif($field eq "start_position_long"){
	    $hasGPS=1;
            $log->debug("i start_position_long=$i\n");
	 }
	 elsif($field eq "start_time"){
	    $iStarttimeLap=$i+1;
            $log->debug("iStarttimeLap=$iStarttimeLap\n");
	 }
	 elsif($field eq "total_elapsed_time"){
	    $iTotalttimesecondsLap=$i+1;
            $log->debug("iTotalttimesecondsLap=$iTotalttimesecondsLap\n");
	 }
	 elsif($field eq "total_distance"){
	    $iLapdistancemetersLap=$i+1;
            $log->debug("iLapdistancemetersLap=$iLapdistancemetersLap\n");
	 }
	 elsif($field eq "avg_speed"){
	    $iSpeedavgLap=$i+1;
            $log->debug("iSpeedavgLap=$iSpeedavgLap\n");
	 }
	 elsif($field eq "max_speed"){
	    $iSpeedmaxLap=$i+1;
            $log->debug("iSpeedmaxLap=$iSpeedmaxLap\n");
	 }
	 elsif($field eq "avg_power"){
	    $iPoweravgLap=$i+1;
            $log->debug("iPoweravgLap=$iPoweravgLap\n");
	 }
	 elsif($field eq "max_power"){
	    $iPowermaxLap=$i+1;
            $log->debug("iPowermaxLap=$iPowermaxLap\n");
	 }
	 elsif($field eq "avg_heart_rate"){
	    $iHeartrateavgLap=$i+1;
            $log->debug("iHeartrateavgLap=$iHeartrateavgLap\n");
	 }
	 elsif($field eq "max_heart_rate"){
	    $iHeartratemaxLap=$i+1;
            $log->debug("iHeartratemaxLap=$iHeartratemaxLap\n");
	 }
	 elsif($field eq "avg_cadence"){
	    $iCadenceavgLap=$i+1;
            $log->debug("iCadenceavgLap=$iCadenceavgLap\n");
	 }
	 elsif($field eq "max_cadence"){
	    $iCadencemaxLap=$i+1;
            $log->debug("iCadencemaxLap=$iCadencemaxLap\n");
	 }
      }

   }
   if(m/Data,\d+,record,/ and !$seenrecord){
      my @l=split /,/;
      $log->debug("$_");
      #---------------------------------------------------------------------
      #analyse the record to find the indeces to use
      for(my $i=0;$i<$#l;$i++){
         $log->debug("i=$i, l[$i]=$l[$i]\n");
	 my $field=$l[$i];
	 if($field eq "timestamp"){
	    $iTimeRecord=$i+1;
            $log->debug("iTimeRecord=$iTimeRecord\n");
	 }
	 if($field eq "distance"){
	    $iDistanceRecord=$i+1;
            $log->debug("iDistanceRecord=$iDistanceRecord\n");
	 }
	 elsif($field eq "start_position_lat"){
	    $hasGPS=1;
            $log->debug("i start_position_lat=$i\n");
	 }
	 elsif($field eq "start_position_long"){
	    $hasGPS=1;
            $log->debug("i start_position_long=$i\n");
	 }
	 elsif($field eq "altitude"){
	    $iAltitudeRecord=$i+1;
            $log->debug("iAltitudeRecord=$iAltitudeRecord\n");
	 }
	 elsif($field eq "speed"){
	    $iSpeedRecord=$i+1;
            $log->debug("iSpeedRecord=$iSpeedRecord\n");
	 }
	 elsif($field eq "power"){
	    $iPowerRecord=$i+1;
            $log->debug("iPowerRecord=$iPowerRecord\n");
	 }
	 elsif($field eq "heart_rate"){
	    $iHeartrateRecord=$i+1;
            $log->debug("iHeartrateRecord=$iHeartrateRecord\n");
	 }
	 elsif($field eq "cadence"){
	    $iCadenceRecord=$i+1;
            $log->debug("iCadenceRecord=$iCadenceRecord\n");
	 }
	 elsif($field eq "temperature"){
	    $iTemperatureRecord=$i+1;
            $log->debug("iTemperatureRecord=$iTemperatureRecord\n");
	 }
      }
      if($iDistanceRecord &&
         $iAltitudeRecord &&
         $iSpeedRecord &&
         $iPowerRecord &&
         $iCadenceRecord &&
         $iTemperatureRecord &&
	 1){
         $seenrecord=1;
	 $log->debug("all i*Record set, done looking\n");
      }
      else{
	 $log->debug("not all i*Record set, keep looking\n");
      }
   }
   if($seenlap and $seenrecord){
      last; #skip reading more entries
   }
}

#---------------------------------------------------------------------------
#start from the top of the file again
seek(CSV,0,0);
while(<CSV>){
   my @l;
   if(m/Data,\d+,lap,/){
      @l=split /,/;
      #print strftime("\%H:\%M:\%S", localtime($l[$iTimeLap])),",";
      $Time=$l[$iTimeLap]+$timeoffsetfit;
      $StartTime=$l[$iStarttimeLap]+$timeoffsetfit;
      $TotalTimeSeconds=$l[$iTotalttimesecondsLap];
      $LapDistanceMeters=$l[$iLapdistancemetersLap];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{TotalTimeSeconds}=$TotalTimeSeconds;
      $exdb{Activity}{$Id}{Lap}{$StartTime}{DistanceMeters}=$LapDistanceMeters;
      $exdb{Activity}{$Id}{Lap}{$StartTime}{SpeedAvg}=$l[$iSpeedavgLap];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{SpeedMax}=$l[$iSpeedmaxLap];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{PowerAvg}=$l[$iPoweravgLap];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{PowerMax}=$l[$iPowermaxLap];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{HeartAvg}=$l[$iHeartrateavgLap];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{HeartMax}=$l[$iHeartratemaxLap];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{CadenceAvg}=$l[$iCadenceavgLap];
      $exdb{Activity}{$Id}{Lap}{$StartTime}{CadenceMax}=$l[$iCadencemaxLap];
   }
   elsif(m/Data,\d+,record,/){
      @l=split /,/;
      #print strftime("\%H:\%M:\%S", localtime($l[$iTimeRecord])),",";
      $Time=$l[$iTimeRecord]+$timeoffsetfit;
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{DistanceMeters}=$l[$iDistanceRecord];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{AltitudeMeters}=$l[$iAltitudeRecord];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{Speed}=$l[$iSpeedRecord];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{Power}=$l[$iPowerRecord];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{HeartRateBpm}=$l[$iHeartrateRecord];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{RunCadence}=$l[$iCadenceRecord];
      $exdb{Activity}{$Id}{Trackpoint}{$Time}{Temperature}=$l[$iTemperatureRecord];

      $log->debug("parse_fit: t=$Time,d=$exdb{Activity}{$Id}{Trackpoint}{$Time}{DistanceMeters},a=$exdb{Activity}{$Id}{Trackpoint}{$Time}{AltitudeMeters},v=$exdb{Activity}{$Id}{Trackpoint}{$Time}{Speed},p=$exdb{Activity}{$Id}{Trackpoint}{$Time}{Power},hr=$exdb{Activity}{$Id}{Trackpoint}{$Time}{HeartRateBpm},cd=$exdb{Activity}{$Id}{Trackpoint}{$Time}{RunCadence},tmp=$exdb{Activity}{$Id}{Trackpoint}{$Time}{Temperature}");
   }
}
#---------------------------------------------------------------------------
#check if we have GPS data
$log->debug("hasGPS=$hasGPS\n");
if($hasGPS){
   #yes - probably cycling outside, on a bike
   $exdb{Activity}{$Id}{SportId}=$SportIdCycling;
}
else{
   #yes - probably cycling inside, on a trainer/rollers
   $exdb{Activity}{$Id}{SportId}=$SportIdCyclotrainer;
}
$exdb{Activity}{$Id}{SMode}=$SModeCycling;
$log->debug("SportId=$exdb{Activity}{$Id}{SportId}, SMode= $exdb{Activity}{$Id}{SMode}\n");
close CSV;
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
#called by parser->parse on the start of every xml tag
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
   elsif($el eq "Position"){
      $hasGPS="true";
   }
   #print "start_element: el=$el\n";
}

#---------------------------------------------------------------------------
#called by parser->parse on the end of every xml tag
#---------------------------------------------------------------------------
sub end_element{
   my ($p, $el) = @_;
   #print "end_element: el=$el\n";
   if($el eq "Activity"){
      $log->debug("Activity completed: Sport=$Sport, Id=$Id\n");
      $exdb{Activity}{$Id}{Sport}=$Sport;
      if($Sport eq "Running"){
         $log->debug("hasGPS=$hasGPS\n");
         if($hasGPS){
	    #has GPS data, probably from running outside
	    $exdb{Activity}{$Id}{SportId}=$SportIdRunning;
	 }
	 else{
	    #has no GPS data, probably from running on a treadmill
	    $exdb{Activity}{$Id}{SportId}=$SportIdTreadmill;
	 }
	 $exdb{Activity}{$Id}{SMode}=$SModeRunning;
         $log->debug("SportId=$exdb{Activity}{$Id}{SportId}, SMode= $exdb{Activity}{$Id}{SMode}\n");
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
   #gen_tcxfile();
   extrapolate_exdb();
   populate_hrmdb();

   #------------------------------------------------------------------------
   if(user_interaction()){
      gen_hrmfile();
      populate_pddb();
      gen_pddfile();
   }

}

#---------------------------------------------------------------------------
elsif($mode eq "e500"){
   parse_fitcsvfile();

   #------------------------------------------------------------------------
   extrapolate_exdb();
   #smooth_exdb();
   populate_hrmdb();

   #------------------------------------------------------------------------
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
