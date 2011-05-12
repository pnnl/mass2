 # -------------------------------------------------------------
# file: plot-depth.gp
# -------------------------------------------------------------
# -------------------------------------------------------------
# Battelle Memorial Institute
# Pacific Northwest Laboratory
# -------------------------------------------------------------
# -------------------------------------------------------------
# Created June 27, 2000 by William A. Perkins
# Last Change: Wed May 11 07:29:24 2011 by William A. Perkins <d3g096@bearflag.pnl.gov>
# -------------------------------------------------------------
# $Id$

set terminal postscript eps mono dashed "Helvetica" 24

set ylabel 'Depth, m'
set yrange [0:3]
set format y '%0.1f'
set xlabel 'Centerline Distance, m'
set xrange [0:310]
set pointsize 0.5
set key bottom

plot '<perl ../../../scripts/mass2slice.pl -t 1 -i plot.nc depth 1 12' using ($3*0.3048):($4*0.3048) title 'Initial Conditions' with lines ls 3, \
     '<perl ../../../scripts/mass2slice.pl -t 2 -i plot.nc depth 1 12' using ($3*0.3048):($4*0.3048) title 'Steady State' with linespoints ls 1, \
     4*0.3048 title 'Analytic' with lines ls 7
