# -------------------------------------------------------------
# file: Makefile
# -------------------------------------------------------------
# -------------------------------------------------------------
# Battelle Memorial Institute
# Pacific Northwest Laboratory
# -------------------------------------------------------------
# -------------------------------------------------------------
# Created January 30, 2002 by William A. Perkins
# Last Change: Fri Oct 17 08:35:07 2008 by William A. Perkins <d3g096@bearflag.pnl.gov>
# -------------------------------------------------------------
# $Id$

MODEL = ../../../mass2
TECPLOT = tecplot

EPSFILES = \
	plot.eps

MODELFILES = \
	bcspecs.dat \
	flow.dat \
	grid1.dat \
	grid2.dat \
	grid3.dat \
	grid4.dat \
	grid5.dat \
	mass2_v027.cfg \
	stage.dat

all: $(EPSFILES)

plot.eps: plot.nc dead.lay
	$(TECPLOT) -b -y plot.eps dead.lay -p ../../../tecplot/macros/export_eps.mcr

plot.nc: $(MODELFILES) $(MODEL)
	$(MODEL)

clean:: 
	rm -f *~
	rm -f error-warning.out mass_source_monitor.out output.out status.out
	rm -f gridplot1.dat
	rm -f plot.nc 
	rm -f batch.log
	rm -f $(EPSFILES)
