# -------------------------------------------------------------
# file: plot-elev.gp
# -------------------------------------------------------------
# -------------------------------------------------------------
# Battelle Memorial Institute
# Pacific Northwest Laboratory
# -------------------------------------------------------------
# -------------------------------------------------------------
# Created June 27, 2000 by William A. Perkins
# Last Change: Mon Mar 18 15:56:00 2002 by William A. Perkins <perk@leechong.pnl.gov>
# -------------------------------------------------------------
# $Id$

set terminal postscript eps color dashed "Helvetica" 14

set samples 2000
set ylabel 'Elevation, feet'
set auto y
set xlabel 'Longitudinal Distance, feet'
set grid y
set grid x
set mytics
set pointsize 0.5
set key below

plot '<perl ../../../scripts/mass2slice.pl -t 1 -i plot.nc wsel 1 12' using 3:4 title 'Initial Conditions' with linespoints 1, \
     '<perl ../../../scripts/mass2slice.pl -t 2 -i plot.nc wsel 1 12' using 3:4 title 'Steady State' with linespoints 3, \
     '<perl ../../../scripts/mass2slice.pl -i plot.nc zbot 1 12' using 3:($4+4) title 'Analytic' with lines 7, \
     '<perl ../../../scripts/mass2slice.pl -i plot.nc zbot 1 12' using 3:4 title 'Bottom' with linespoints 7
