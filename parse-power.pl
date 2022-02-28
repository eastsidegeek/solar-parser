#!/usr/bin/perl

use Time::Local;

use Astro::Sunrise;

$file = $ARGV[0];
$panelpeakpower = $ARGV[1];
$panelsmin = $ARGV[2];
$panelsmax = $ARGV[3];
$battcapkwh = $ARGV[4];
$battsmin = $ARGV[5];
$battsmax = $ARGV[6];

open(my $fh, "<", $file) or die "Couldn't open file $file";

my @time;
my @power;
my $tmptime;
my @parsetime;
my @sunrises;
my @sunsets;
my @noons;

my $kwhcost = 0.1;

my $i=0;

while(<$fh>) {
	if($i>0) {
		($tmptime,$power[$i]) = split(/,/,$_);
		chomp($power[$i]);
		#1/14/2020  11:04:00 AM
		@parsetime=split(/[\/ :]/, $tmptime);
		
		$time[$i] = timelocal(0,$parsetime[4],$parsetime[3],$parsetime[1],($parsetime[0]-1),$parsetime[2]);
		$today = int($parsetime[0])."-".int($parsetime[1]);
		#print "Recording day ".$today."\n";
		
		if(!exists($sunrises{$today})) {
			($sunrise,$sunset) = sunrise( {year=>$parsetime[2] , month=> $parsetime[0], day=> $parsetime[1],
															 lon=>86, lat=>36, tz=>6, isdst=>0 } );
		
						
			my ($srh,$srm) = split(/:/,$sunrise);
			my ($ssh,$ssm) = split(/:/,$sunset);
			
			$sunrises{$today} = timelocal(0, $srm, $srh, $parsetime[1],($parsetime[0]-1),$parsetime[2]);
			$sunsets{$today} = timelocal(0, $ssm, $ssh, $parsetime[1],($parsetime[0]-1),$parsetime[2]);
			$noons{$today} = int(($sunsets{$today} + $sunrises{$today})/2);
		}
		
		
		#$time[$i] = str2time($tmptime);
	}
	$i++;
}

my $total = $i;
my $scen = 1;

for(my $panels = $panelsmin; $panels <= $panelsmax; $panels++) {
	for(my $batts = $battsmin; $batts <= $battsmax; $batts++) {
		my $currcharge = 0; # kwh in batteries
		my $maxcharge = $batts * $battcapkwh;
		my $exported = 0; 
		my $nochargetime = 0;
		my $maxchargetime = 0;
		my $totalproduction = 0;
		my $totaldelta = 0;
		
		print "---- Scenario ".$scen." -----\n";
		$scen++;
		print "Peak power per panel: ".$panelpeakpower."W\n";
		print "Panels: ".$panels."\n";
		print "Batteries: ".$batts."\n";
		print "Battery capacity: ".$maxcharge."kWh\n";
		
		for($i=0; $i < $total ; $i++) {
			$i++;
			
			my ($sec, $min, $hour, $day,$month,$year) = (localtime($time[$i]))[0,1,2,3,4,5];
			my $today = ($month+1)."-".$day;
			my $sunrise = $sunrises{$today};
			my $sunset = $sunsets{$today};
			my $noon = $noons{$today};
			
			#print "Time is ".$today.", sunrise ".$sunrise.", sunset ".$sunset."\n";
			
			if($time[$i] <= $sunrise) { $output = 0; }
			elsif($time[$i] >= $sunset) { $output = 0; }
			else {
				# generate the point on the insolation parabola
				$b = ($sunset - (($sunrise + $sunset) /2));
				my $a = (-1) / ($b * $b);
				my $mult = ($a * (($time[$i]) * $time[$i]))-(($sunrise+$sunset)*$a* $time[$i])+($sunrise*$sunset*$a);
				$output = $mult * $panels * $panelpeakpower;
				$output = $output /1000;
				
			} # end else block
			
			# here's where we take solar output and figure out charging, excess, etc
			$powerdelta = $power[$i] - $output;
			$totalproduction += ($output/60);
			$kwhdelta = $powerdelta/60; #assumes we have minutely data
			$totaldelta += ($kwhdelta);
			$currcharge = $currcharge - $kwhdelta;
			if($currcharge < 0) { $currcharge=0; $nochargetime++;}
			if($currcharge > $maxcharge) { $exported += ($currcharge-$maxcharge); $currcharge = $maxcharge; $maxchargetime++;}
			
			
			#print $time[$i].",".$power[$i].",".$output."\n";
		} # end inner loop on data
		
		printf ("Total exported: %.1fkWh \n",($exported));
		print "Minutes at no charge: ".$nochargetime."\n";
		print "Minutes at max charge: ".$maxchargetime."\n";
		printf ("Total panel production: %.1f\n", $totalproduction);
		printf ("Total delta vs demand: %.1f\n",$totaldelta);
		
		print "\n";
	} # end for batts
} # end for panels