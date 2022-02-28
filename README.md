# solar-parser
Models solar generation and battery usage based on historical home power draw


User provides an input file of format 
timestamp,kW 
(sample input files from my home are provided)

User also provides the following parameters for modeling: 
Peak Panel Power - Rated peak output for the chosen model of solar panel 
Minimum Panel Count 
Maximum Panel Count 
Battery capacity in kWh 
Minimum battery count 
Maximum battery count

usage: perl parse-power.pl [file] [panel-peak-kwh] [panels-min] [panels-max] [battery-cap-kwh] [batteries-min] [batteries-max]

For data points in the input file, script models battery usage and expected power output.

Other parameters to modify in script:
Latitude and longitude - these will impact expected sunrise and sunset times
Time zone (same)
Daylight savings y/n

This script assumes ideally positioned panels (directly southern facing, ideal pitch for latitude). For a more generalized calculation we would need to account for panel angle and pitch. I happen to have a south-facing roof with approxmiately the ideal pitch so I didn't implement this, sorry.

Sample output file also included.
