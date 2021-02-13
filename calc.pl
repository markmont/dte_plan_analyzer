#!/usr/bin/perl -w

use DateTime;


# Debug booleans
my $general_debug0 = 0;
my $d1debug = 0;
my $d1_2debug = 0;
my $d1_8debug = 0;


# Constants

my $weekday_peak_first_hr = 11;
my $weekday_peak_last_hr = 18; #The 6pm-o'clock hour. Off-peak starts at 7pm-o'clock

my $summer_first_mo = 6;
my $summer_last_mo = 10;

my $winter_peak_rate = 20.213;
my $winter_offpeak_rate = 11.82;
my $summer_peak_rate = 22.713;
my $summer_offpeak_rate = 12.032;

my $standard_rate_tier1 = 15.287;
my $standard_rate_tier2 = 17.271;

my $dpp_rate_on_peak = 23.212;
my $dpp_rate_mid_peak = 15.832;
my $dpp_rate_off_peak = 11.405;
my $dpp_rate_critical_peak = 101.611;

# Regular vars

my $std_kwh_today = 0;

my $file = $ARGV[0];

my $std_tier1_kwh = 0;
my $std_tier2_kwh = 0;

my $winter_peak_kwh = 0;
my $winter_offpeak_kwh = 0;
my $summer_peak_kwh = 0;
my $summer_offpeak_kwh = 0;

my $dpp_critical_kwh = 0;
my $dpp_on_kwh = 0;
my $dpp_mid_kwh = 0;
my $dpp_off_kwh = 0;

my ($date, $year, $time, $hour, $ampm, $month, $day, $usage, $dayofweek);

# Note: dayofweek 1=Monday, 7=Sunday


sub usage 
{
	print <<EOF;
Usage: $0 <input.csv>

A quick and very dirty script to examine a year's worth of your DTE Energy electric usage and calculate your cost on the D1 standard service plan vs the D1.2 time-of-day service plan.
EOF
}





if(@ARGV != 1) {
	usage;
	exit 1;
}

open (my $datafile, '<', $file) or die "Could not open input file $file.\n";

my @peak_usage = ();
my $peak_today = 0;
while (my $line = <$datafile>)
{
	next if $. == 1; # skip first line

	my @fields = split "," , $line;
	$date = $fields[1];
	$time = $fields[2];
	$usage = $fields[3];

	$date =~ s/\"//g;
	$time =~ s/\"//g;
	$usage =~ s/\"//g;

	@fields = split "/", $date;
	$month = $fields[0];
	$day = $fields[1];
	$year = $fields[2];

	@fields = split ":", $time;
	$hour = $fields[0];

	@fields = split " ", $time;
	$ampm = $fields[1];

	if (($ampm eq "PM") && ($hour != 12)) { $hour = $hour + 12; }

	if (($ampm eq "AM") && ($hour == 12)) { $hour = 0; }

	my $dt = DateTime->new(
		year => $year,
		month => $month,
		day => $day,
	);
	
	$dayofweek = $dt->day_of_week;

        next if ($dayofweek == 6) || ($dayofweek == 7); #It's a weekend
        next if ($hour < 15) || ($hour > 19); # It's not peak

        if ($hour == 15) { $peak_today = 0; }
        $peak_today += $usage;
        if ($hour == 19)
        {
                push (@peak_usage, { date => "$year-$month-$day", usage => $peak_today });
        }
}
close ($datafile);
my @top_peak_usage = sort { $b->{usage} <=> $a->{usage} } @peak_usage;
@top_peak_usage = @top_peak_usage[0..13];
my %is_date_critical_peak = map { $_->{date} => 1 } @top_peak_usage;

open (my $data, '<', $file) or die "Could not open input file $file.\n";

while (my $line = <$data>)
{
	if ($general_debug0 == 1)
	{
		print "$line\n";
	}
	next if $. == 1; # skip first line

	my @fields = split "," , $line;
	$date = $fields[1];
	$time = $fields[2];
	$usage = $fields[3];

	$date =~ s/\"//g;
	$time =~ s/\"//g;
	$usage =~ s/\"//g;

	@fields = split "/", $date;
	$month = $fields[0];
	$day = $fields[1];
	$year = $fields[2];

	@fields = split ":", $time;
	$hour = $fields[0];

	@fields = split " ", $time;
	$ampm = $fields[1];

	if (($ampm eq "PM") && ($hour != 12))
	{
		$hour = $hour + 12;
	}

	if (($ampm eq "AM") && ($hour == 12))
	{
		$hour = 0;
	}

	my $dt = DateTime->new(
		year => $year,
		month => $month,
		day => $day,
	);
	
	$dayofweek = $dt->day_of_week;


	if ($general_debug0 == 1)
	{
		print ">$date< >$hour< >$usage<\n";
		print ">$month< >$day< >$year< >$time< >$hour< >$ampm< >$usage< >$dayofweek<\n";
	}


	#Accumulate standard (D1) usage
	if ($hour == 23)
	{
		if ($std_kwh_today < 17)
		{
			$std_tier1_kwh = $std_tier1_kwh + $usage;
			$std_kwh_today = 0;
			if ($d1debug == 1)
			{
				print "DEBUG: Adding $usage kWh to std_tier1\n";
				print "DEBUG: Resetting daily accumulation\n";
			}
		}
		else
		{
			$std_tier2_kwh = $std_tier2_kwh + $usage;
			$std_kwh_today = 0;
			if ($d1debug == 1)
			{
				print "DEBUG: Adding $usage kWh to std_tier2\n";
				print "DEBUG: Resetting daily accumulation\n";
			}
		}
	}
	else
	{
		if ($std_kwh_today < 17)
		{
			$std_tier1_kwh = $std_tier1_kwh + $usage;
			$std_kwh_today = $std_kwh_today + $usage;
			if ($d1debug == 1)
			{
                        	print "DEBUG: Adding $usage kWh to std_tier1\n";
			}
		}
		else
		{
			$std_tier2_kwh = $std_tier2_kwh + $usage;
			$std_kwh_today = $std_kwh_today + $usage; #unnecessary
			if ($d1debug == 1)
			{
				print "DEBUG: Adding $usage kWh to std_tier2\n";
			}
		}
	}

	#Accumulate time-of-day (D1.2) usage
	if (($month < $summer_first_mo) || ($month > $summer_last_mo)) #It's winter
	{
		if ($d1_2debug == 1)
		{
			print "DEBUG: Rate: Winter    ";
		}
		if (($dayofweek == 6) || ($dayofweek == 7)) #It's a weekend
		{
			if ($d1_2debug == 1)
			{
				print "Adding $usage kWh to off-peak (weekend)\n";
			}
			$winter_offpeak_kwh = $winter_offpeak_kwh + $usage;
		}
		else
		{
			if (($hour < $weekday_peak_first_hr) || ($hour > $weekday_peak_last_hr))
			{
				if ($d1_2debug == 1)
				{
					print "Adding $usage kWh to off-peak (weekday)\n";
				}
				$winter_offpeak_kwh = $winter_offpeak_kwh + $usage;
			}
			else
			{
				if ($d1_2debug == 1)
				{
					print "Adding $usage kWh to on-peak\n";
				}
				$winter_peak_kwh = $winter_peak_kwh + $usage;
			}
		}
	}
	else #It's summer
	{
		if ($d1_2debug == 1)
		{
                	print "DEBUG: Rate: Summer    ";
		}
                if (($dayofweek == 6) || ($dayofweek == 7)) #It's a weekend
                {
			if ($d1_2debug == 1)
			{
                        	print "Adding $usage kWh to off-peak (weekend)\n";
			}
                        $summer_offpeak_kwh = $summer_offpeak_kwh + $usage;
                }
                else
                {
                        if (($hour < $weekday_peak_first_hr) || ($hour > $weekday_peak_last_hr))
                        {
				if ($d1_2debug == 1)
				{
                                	print "Adding $usage kWh to off-peak (weekday)\n";
				}
                                $summer_offpeak_kwh = $summer_offpeak_kwh + $usage;
                        }
                        else
                        {
				if ($d1_2debug == 1)
				{
                                	print "Adding $usage kWh to on-peak\n";
				}
                                $summer_peak_kwh = $summer_peak_kwh + $usage;
                        }
                }
	}

	#Accumulate dynamic peak pricing usage
        if ( ($dayofweek == 6) || ($dayofweek == 7) # weekend
          || (($month == 1) && ($day == 1)) # New Year's Day
          || (($month == 4) && ($day == 10)) # Good Friday
          || (($month == 5) && ($day == 25)) # Memorial Day
          || (($month == 7) && ($day == 6)) # Independence Day
          || (($month == 9) && ($day == 7)) # Labor Day
          || (($month == 11) && ($day == 26)) # Thanksgiving
          || (($month == 12) && ($day == 25)) # Christmas
            )
        {
                $dpp_off_kwh += $usage;
        }
        elsif ($hour == 23 || $hour < 7)
        {
                $dpp_off_kwh += $usage;
        }
        elsif ($hour >= 15 && $hour <= 19)
        {
                if (defined($is_date_critical_peak{"$year-$month-$day"}))
                {
                        $dpp_critical_kwh += $usage;
                }
                else
                {
                        $dpp_on_kwh += $usage;
                }
        }
        else
        {
                        $dpp_mid_kwh += $usage;
        }
}

close ($data);

my $std_total_kwh = int($std_tier1_kwh + $std_tier2_kwh);
my $std_tier1_dollars = int(($std_tier1_kwh * $standard_rate_tier1) / 100);
my $std_tier2_dollars = int(($std_tier2_kwh * $standard_rate_tier2) / 100);
my $std_total_dollars = int($std_tier1_dollars + $std_tier2_dollars);
$std_tier1_kwh = int($std_tier1_kwh);
$std_tier2_kwh = int($std_tier2_kwh);



my $summer_peak_dollars = int(($summer_peak_kwh * $summer_peak_rate) / 100);
my $winter_peak_dollars = int(($winter_peak_kwh * $winter_peak_rate) / 100);
my $summer_offpeak_dollars = int(($summer_offpeak_kwh * $summer_offpeak_rate) / 100);
my $winter_offpeak_dollars = int(($winter_offpeak_kwh * $winter_offpeak_rate) / 100);
my $total_tod_kwh = int($summer_peak_kwh + $summer_offpeak_kwh + $winter_peak_kwh + $winter_offpeak_kwh);
my $total_tod_dollars = int($summer_peak_dollars + $summer_offpeak_dollars + $winter_peak_dollars + $winter_offpeak_dollars);
$summer_peak_kwh = int($summer_peak_kwh);
$summer_offpeak_kwh = int($summer_offpeak_kwh);
$winter_peak_kwh = int($winter_peak_kwh);
$winter_offpeak_kwh = int($winter_offpeak_kwh);

my $dpp_critical_dollars = int(($dpp_critical_kwh * $dpp_rate_critical_peak) / 100);
my $dpp_on_dollars = int(($dpp_on_kwh * $dpp_rate_on_peak) / 100);
my $dpp_mid_dollars = int(($dpp_mid_kwh * $dpp_rate_mid_peak) / 100);
my $dpp_off_dollars = int(($dpp_off_kwh * $dpp_rate_off_peak) / 100);
my $total_dpp_kwh = int($dpp_critical_kwh + $dpp_on_kwh + $dpp_mid_kwh + $dpp_off_kwh);
my $total_dpp_dollars = $dpp_critical_dollars + $dpp_on_dollars + $dpp_mid_dollars + $dpp_off_dollars;
$dpp_critical_kwh = int($dpp_critical_kwh);
$dpp_on_kwh = int($dpp_on_kwh);
$dpp_mid_kwh = int($dpp_mid_kwh);
$dpp_off_kwh = int($dpp_off_kwh);

print "\n\n";
print "---Standard D1 Plan---\n";
print "Tier 1 kWh: $std_tier1_kwh Cost: \$$std_tier1_dollars\n";
print "Tier 2 kWh: $std_tier2_kwh Cost: \$$std_tier2_dollars\n";
print "Total  kWh: $std_total_kwh Cost: \$$std_total_dollars\n";

print "\n";
print "---Time-of-Day D1.2 Plan---\n";
print "Summer Peak     kWh: $summer_peak_kwh Cost: \$$summer_peak_dollars\n";
print "Summer Off-Peak kWh: $summer_offpeak_kwh Cost: \$$summer_offpeak_dollars\n";
print "Winter Peak     kWh: $winter_peak_kwh Cost: \$$winter_peak_dollars\n";
print "Winter Off-Peak kWh: $winter_offpeak_kwh Cost: \$$winter_offpeak_dollars\n";
print "Total           kWh: $total_tod_kwh Cost: \$$total_tod_dollars\n";

print "\n";
print "---Dynamic Peak Pricing Plan (worst case)---\n";
print "Days with top peak-hours usage:\n";
foreach my $d (@top_peak_usage)
{
        printf ("    %s %2.3f kWh \$%2.2f\n", $d->{date}, $d->{usage}, $d->{usage} * $dpp_rate_critical_peak / 100);
}
print "Critical-Peak   kWh: $dpp_critical_kwh Cost: \$$dpp_critical_dollars\n";
print "On-Peak         kWh: $dpp_on_kwh Cost: \$$dpp_on_dollars\n";
print "Mid-Peak        kWh: $dpp_mid_kwh Cost: \$$dpp_mid_dollars\n";
print "Off-Peak        kWh: $dpp_off_kwh Cost: \$$dpp_off_dollars\n";
print "Total           kWh: $total_dpp_kwh Cost: \$$total_dpp_dollars\n";

