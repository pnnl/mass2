# -------------------------------------------------------------
# file: Makefile
# -------------------------------------------------------------
# -------------------------------------------------------------
# Battelle Memorial Institute
# Pacific Northwest Laboratory
# -------------------------------------------------------------
# -------------------------------------------------------------
# Created January 30, 2002 by William A. Perkins
# Last Change: Tue Jan  6 09:01:41 2004 by William A. Perkins <perk@leechong.pnl.gov>
# -------------------------------------------------------------
# $Id$

MODEL = ../../../mass2

EPSFILES = \
	plot-depth.eps \
	plot-elev.eps

MODELFILES = \
	mass2_v027.cfg \
	bcspecs.dat \
	flow.dat \
	grid.dat \
	stage.dat

all: $(EPSFILES)

$(EPSFILES): plot.nc


plot.nc: $(MODELFILES) $(MODEL)
	$(MODEL)

%.eps: %.gp
	gnuplot $< > $@

clean:: 
	rm -f *~
	rm -f error-warning.out mass_source_monitor.out output.out status.out
	rm -f gridplot1.dat
	rm -f plot.nc 
	rm -f $(EPSFILES)