# -------------------------------------------------------------
# file: Makefile
# -------------------------------------------------------------
# -------------------------------------------------------------
# Battelle Memorial Institute
# Pacific Northwest Laboratory
# -------------------------------------------------------------
# -------------------------------------------------------------
# Created January 30, 2002 by William A. Perkins
# Last Change: Tue Apr  8 12:01:35 2003 by William A. Perkins <perk@leechong.pnl.gov>
# -------------------------------------------------------------
# $Id$

MODEL = ../../../mass2_v027
TECPLOT = tecplot

EPSFILES = \
	plot.eps

MODELFILES = \
	bcspecs.dat \
	flow.dat \
	grid1.dat \
	grid2.dat \
	mass2_v027.cfg \
	stage.dat \
	zero.dat

all: $(EPSFILES)

plot.eps: plot.nc wall.lay
	$(TECPLOT) -b -y plot.eps wall.lay -p ../../../tecplot/macros/export_eps.mcr

plot.nc: $(MODELFILES) $(MODEL)
	$(MODEL)

clean:: 
	rm -f *~
	rm -f error-warning.out mass_source_monitor.out output.out status.out
	rm -f gridplot1.dat
	rm -f plot.nc 
	rm -f batch.log
	rm -f $(EPSFILES)

