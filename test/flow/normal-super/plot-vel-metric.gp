 # -------------------------------------------------------------
# file: plot-depth.gp
# -------------------------------------------------------------
# -------------------------------------------------------------
# Battelle Memorial Institute
# Pacific Northwest Laboratory
# -------------------------------------------------------------
# -------------------------------------------------------------
# Created June 27, 2000 by William A. Perkins
# Last Change: Wed May 11 07:31:22 2011 by William A. Perkins <d3g096@bearflag.pnl.gov>
# -------------------------------------------------------------
# $Id$

set terminal postscript eps mono dashed "Helvetica" 24

set samples 2000
set ylabel 'Velocity, m/s'
# set yrange [0:3]
set xlabel 'Longitudinal Distance, m'
# set grid y
# set grid x
# set mytics
set pointsize 0.5
set key left

plot '<perl ../../../scripts/mass2slice.pl -t 1 -i plot.nc vmag 1 5' using ($3*0.3048):($4*0.3048) title 'Initial Conditions' with lines ls 3, \
     '<perl ../../../scripts/mass2slice.pl -l -i plot.nc vmag 1 5' using ($3*0.3048):($4*0.3048) title 'Steady State' with linespoints ls 1
