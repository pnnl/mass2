#!/sw/bin/gnuplot -persist
#
#    
#    	G N U P L O T
#    	Version 4.2 patchlevel 4 
#    	last modified Sep 2008
#    	System: Darwin 8.11.0
#    
#    	Copyright (C) 1986 - 1993, 1998, 2004, 2007, 2008
#    	Thomas Williams, Colin Kelley and many others
#    
#    	Type `help` to access the on-line reference manual.
#    	The gnuplot FAQ is available from http://www.gnuplot.info/faq/
#    
#    	Send bug reports and suggestions to <http://sourceforge.net/projects/gnuplot>
#    
set terminal postscript eps enhanced color dashed "Helvetica" 14 
unset clip points
set clip one
unset clip two
set bar 1.000000
set xdata time
set ydata
set zdata
set x2data
set y2data
set timefmt x "%m-%d-%Y %H:%M:%S"
set timefmt y "%m-%d-%Y %H:%M:%S"
set timefmt z "%m-%d-%Y %H:%M:%S"
set timefmt x2 "%m-%d-%Y %H:%M:%S"
set timefmt y2 "%m-%d-%Y %H:%M:%S"
set timefmt cb "%m-%d-%Y %H:%M:%S"
set boxwidth
set style fill  empty border
set dummy x,y
set format x "%b%d\n%Y"
set format y "% g"
set format x2 "% g"
set format y2 "% g"
set format z "% g"
set format cb "% g"
set angles radians
unset grid
set key title ""
unset label
unset arrow
unset style line
unset style arrow
unset logscale
set offsets 0, 0, 0, 0
set pointsize 1
set encoding default
unset polar
unset parametric
unset decimalsign
set view 60, 30, 1, 1
set samples 100, 100
set isosamples 10, 10
set surface
unset contour
set clabel '%8.3g'
set mapping cartesian
set datafile separator whitespace
unset hidden3d
set cntrparam order 4
set cntrparam linear
set cntrparam levels auto 5
set cntrparam points 5
set size ratio 0 1,1
set origin 0,0
set style data points
set style function lines
set xzeroaxis linetype 0 linewidth 1.000
set yzeroaxis linetype -2 linewidth 1.000
set x2zeroaxis linetype -2 linewidth 1.000
set y2zeroaxis linetype -2 linewidth 1.000
set ticslevel 0.5
set mxtics default
set mytics default
set mztics default
set mx2tics default
set my2tics default
set mcbtics default
set xtics border mirror norotate 
set xtics autofreq 
set ytics border mirror norotate 
set ytics autofreq 
set ztics border nomirror norotate 
set ztics autofreq 
set nox2tics
set noy2tics
set cbtics border mirror norotate
set cbtics autofreq 
set title "" 
set timestamp bottom 
set rrange [ * : * ] noreverse nowriteback  # (currently [0.00000:10.0000] )
set trange [ * : * ] noreverse nowriteback  # (currently ["31/12/99,23:59":"01/01/00,00:00"] )
set urange [ * : * ] noreverse nowriteback  # (currently ["31/12/99,23:59":"01/01/00,00:00"] )
set vrange [ * : * ] noreverse nowriteback  # (currently ["31/12/99,23:59":"01/01/00,00:00"] )
set xlabel "" 
set xrange [ "01-01-1995 00:00:00" : "01-01-2001 00:00:00" ] noreverse nowriteback
set x2range [ * : * ] noreverse nowriteback  # (currently [-10.0000:10.0000] )
set ylabel "Temperature, C" 
set y2label "" 
set yrange [ * : * ] noreverse nowriteback  # (currently [-10.0000:10.0000] )
set y2range [ * : * ] noreverse nowriteback  # (currently [-10.0000:10.0000] )
set zlabel "" 
set zrange [ * : * ] noreverse nowriteback  # (currently [-10.0000:10.0000] )
set cblabel "" 
set cbrange [ * : * ] noreverse nowriteback  # (currently [-10.0000:10.0000] )
set zero 1e-08
set lmargin  -1
set bmargin  -1
set rmargin  -1
set tmargin  -1
set locale "C"
set pm3d explicit at s
set pm3d scansautomatic
set palette positive nops_allcF maxcolors 0 gamma 1.5 color model RGB 
set palette rgbformulae 7, 5, 15
set colorbox default
set loadpath 
set fontpath 
set fit noerrorvariables
plot "met.dat" using 1:3 title "Air" with lines ls 3, \
     "gage_1.out" using 1:10 title "Pond" with lines ls 1
#    EOF
