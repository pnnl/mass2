 # -------------------------------------------------------------
# file: plot-conc.gp
# -------------------------------------------------------------
# -------------------------------------------------------------
# Battelle Memorial Institute
# Pacific Northwest Laboratory
# -------------------------------------------------------------
# -------------------------------------------------------------
# Created June 27, 2000 by William A. Perkins
# Last Change: 2014-06-24 08:45:29 d3g096
# -------------------------------------------------------------
# $Id$

set terminal postscript eps mono dashed "Helvetica" 24

u = 2.0
K = 0.2
lamda = 6.9315E-05
lamda = 1.386E-04
Ci = 10
a = 4*K*lamda/u**2
Co = Ci*((2/a)*(sqrt(a + 1) - 1))
C(x) = Co*exp(-((u*x)/(2*K))*(sqrt(a+1) - 1))
# C2(x) = Ci*exp(-lamda*x/u)

set samples 2000
set ylabel 'Concentration'
set yrange [4.9:10.1]
set format y '%.1f'
set xlabel 'Longitudinal Distance, feet'
set xrange [0:3100]
set pointsize 0.5
set key

plot "<awk 'NR > 20 {print $1, $17}' probe.dat" using ($1*0.3048):2 title 'Simulated' with points ls 3, \
     C(x/0.3048) title 'Analytic Solution' with lines ls 1