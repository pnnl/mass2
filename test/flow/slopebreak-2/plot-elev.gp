# -------------------------------------------------------------
# file: plot-elev.gp
# -------------------------------------------------------------
# -------------------------------------------------------------
# Battelle Memorial Institute
# Pacific Northwest Laboratory
# -------------------------------------------------------------
# -------------------------------------------------------------
# Created June 27, 2000 by William A. Perkins
# Last Change: Fri Jan  2 10:16:47 2004 by William A. Perkins <perk@leechong.pnl.gov>
# -------------------------------------------------------------
# $Id$

set terminal postscript eps enhanced mono dashed "Helvetica" 24

set samples 2000
set ylabel 'Elevation, feet'
set format y '%.0f'
set auto y
set xlabel 'Longitudinal Distance, feet'
# set grid y
# set grid x
set mytics
set pointsize 0.5
set key

plot '<perl ../../../scripts/mass2slice.pl -t 1 -i plot.nc wsel 1 5' using 3:4 title 'Initial Conditions' with lines 3, \
     '<perl ../../../scripts/mass2slice.pl -t 2 -i plot.nc wsel 1 5' using 3:4 title 'Steady State' with linespoints 1, \
     '<perl ../../../scripts/mass2slice.pl -i plot.nc zbot 1 5' using 3:4 title 'Bottom' with linespoints 7
