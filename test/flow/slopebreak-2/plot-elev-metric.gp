# -------------------------------------------------------------
# file: plot-elev.gp
# -------------------------------------------------------------
# -------------------------------------------------------------
# Battelle Memorial Institute
# Pacific Northwest Laboratory
# -------------------------------------------------------------
# -------------------------------------------------------------
# Created June 27, 2000 by William A. Perkins
# Last Change: Thu Jan  8 12:12:03 2004 by William A. Perkins <perk@leechong.pnl.gov>
# -------------------------------------------------------------
# $Id$

set terminal postscript eps enhanced mono dashed "Helvetica" 24

set samples 2000
set ylabel 'Elevation, m'
set format y '%.0f'
set auto y
set xlabel 'Longitudinal Distance, m'
set xrange [0:6300]
# set grid y
# set grid x
# set mytics
set pointsize 0.5
set key

plot '<perl ../../../scripts/mass2slice.pl -t 1 -i plot.nc wsel 1 5' using ($3*0.3048):($4*0.3048) title 'Initial Conditions' with lines 3, \
     '<perl ../../../scripts/mass2slice.pl -t 2 -i plot.nc wsel 1 5' using ($3*0.3048):($4*0.3048) title 'Steady State' with linespoints 1, \
     '<perl ../../../scripts/mass2slice.pl -i plot.nc zbot 1 5' using ($3*0.3048):($4*0.3048) title 'Bottom' with lines 7
