# -------------------------------------------------------------
# file: plot-elev.gp
# -------------------------------------------------------------
# -------------------------------------------------------------
# Battelle Memorial Institute
# Pacific Northwest Laboratory
# -------------------------------------------------------------
# -------------------------------------------------------------
# Created June 27, 2000 by William A. Perkins
# Last Change: Fri Jan  2 11:14:05 2004 by William A. Perkins <perk@leechong.pnl.gov>
# -------------------------------------------------------------
# $Id$

set terminal postscript eps mono dashed "Helvetica" 24

set samples 2000
set ylabel 'Elevation, m'
set xrange [0:3100]
set auto y
set xlabel 'Longitudinal Distance, m'
# set grid y
# set grid x
# set mytics
set pointsize 0.5
set key screen 0.85, 0.4

set arrow from first 1524, graph 0.0 to first 1524, graph 1.0 nohead lt 0 

plot '<perl ../../../scripts/mass2slice.pl -t 1 -i plot.nc wsel 1 5 2 5' using ($3*0.3048):($4*0.3048) title 'Initial Conditions' with lines 3, \
     '<perl ../../../scripts/mass2slice.pl -l -i plot.nc wsel 1 5 2 5' using ($3*0.3048):($4*0.3048) title 'Steady State' with linespoints 1, \
     '<perl ../../../scripts/mass2slice.pl -i plot.nc zbot 1 5 2 5' using ($3*0.3048):($4*0.3048) title 'Bottom' with lines 7
