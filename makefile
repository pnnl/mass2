# -------------------------------------------------------------
# file: Makefile
# Makefile for mass2
# -------------------------------------------------------------
# -------------------------------------------------------------
# Battelle Memorial Institute
# Pacific Northwest Laboratory
# -------------------------------------------------------------
# -------------------------------------------------------------
# Created June  1, 1998 by William A. Perkins
# Last Change: Wed Nov 17 09:54:55 1999 by William A. Perkins <perk@tophet.pnl.gov>
# -------------------------------------------------------------


F90 = f90
COMPILE.f90 = $(F90) $(F90FLAGS) -c $(DEBUG)
LINK.f90 = $(F90) $(LDFLAGS)
MOD=mod

# Options supplied by the SGI guy (require 512 MB of virtual memory)
# DEBUG =  -O3
# FLAGS = $(DEBUG) -r10000 -n32 -OPT:Olimit=0 -LNO:prefetch=2

# stuff to include netcdf

NETCDFDIR = /usr/unsupported/ucar
NETCDFFLAGS = -I$(NETCDFDIR)/include
NETCDFLDFLAGS = -L$(NETCDFDIR)/lib 
NETCDFLIBS = -lnetcdf

# Options that will work on erebus:
DEBUG =  -Ofast
FLAGS = $(NETCDFFLAGS) $(DEBUG) # -TARG:platform=IP30  -OPT:Olimit=0 

# general compile/link flags

MAINDEBUG = $(DEBUG)
F90FLAGS = $(FLAGS)
LIBLOC = 
LDFLAGS = $(NETCDFLDFLAGS) ${LIBLOC} $(FLAGS)
LIBS = $(NETCDFLIBS) -lfpe

TARGET = mass2_v025
SRCS = \
     julian.f90 \
     date_time_module.f90 \
     gas_coeffs_module.f90 \
     gas_functions_module.f90 \
     scalars_module.f90 \
     energy_flux_module.f90 \
     gage_output_module.f90 \
     plot_output.f90 \
     netcdferror.f90 \
     global_module_023.f90 \
     io_routines_module.f90 \
     table_bc_module.f90 \
     block_bc_module.f90 \
     met_data_module.f90 \
     profile_init.f90 \
     mass2_main_025.f90

OBJS = $(SRCS:%.f90=%.o)

MODULES = 					\
    BLOCK_BOUNDARY_CONDITIONS.mod		\
    DATE_TIME.mod				\
    ENERGY_FLUX.mod				\
    F90_UNIX_PROC.mod			\
    GAGE_OUTPUT.mod				\
    GAS_COEFFS.mod				\
    GAS_FUNCTIONS.mod			\
    GLOBALS.mod					\
    IO_ROUTINES_MODULE.mod		\
    JULIAN.mod					\
    MET_DATA_MODULE.mod			\
    PLOT_OUTPUT.mod				\
    SCALARS.mod					\
    TABLE_BOUNDARY_CONDITIONS.mod

${TARGET}: ${OBJS}
	${LINK.f90} ${OBJS} ${LIBS} -o ${TARGET}

clean::
	rm -f ${TARGET}

DATE_TST_OBJ = julian.o date_time_module.o date_time_test.o 
date_time_test: ${DATE_TST_OBJ}
	${LINK.f90} ${DATE_TST_OBJ} ${LIBS} -o $@

clean::
	rm -rf date_time_test

# dependancies for individual object files

block_bc_module.o: block_bc_module.f90 \
		TABLE_BOUNDARY_CONDITIONS.$(MOD)
BLOCK_BOUNDARY_CONDITIONS.$(MOD): block_bc_module.o

date_time_module.o: date_time_module.f90 JULIAN.$(MOD)
DATE_TIME.$(MOD): date_time_module.o

energy_flux_module.o: energy_flux_module.f90
ENERGY_FLUX.$(MOD): energy_flux_module.o

gage_output_module.o: gage_output_module.f90 GLOBALS.$(MOD) \
	SCALARS.$(MOD) GAS_FUNCTIONS.$(MOD) $(STUPIDMOD)
GAGE_OUTPUT.$(MOD): gage_output_module.o

gas_coeffs_module.o: gas_coeffs_module.f90
GAS_COEFFS.$(MOD): gas_coeffs_module.o

gas_functions_module.o: gas_functions_module.f90 GAS_COEFFS.$(MOD)
GAS_FUNCTIONS.$(MOD): gas_functions_module.o

global_module_023.o: global_module_023.f90 $(STUPIDMOD) 
GLOBALS.$(MOD): global_module_023.o

io_routines_module.o: io_routines_module.f90
IO_ROUTINES_MODULE.$(MOD): io_routines_module.o

julian.o: julian.f90
JULIAN.$(MOD): julian.o

mass2_main_025.o: mass2_main_025.f90 \
   GLOBALS.$(MOD) IO_ROUTINES_MODULE.$(MOD) BLOCK_BOUNDARY_CONDITIONS.$(MOD) \
   TABLE_BOUNDARY_CONDITIONS.$(MOD) DATE_TIME.$(MOD) SCALARS.$(MOD) \
   MET_DATA_MODULE.$(MOD) ENERGY_FLUX.$(MOD) GAS_FUNCTIONS.$(MOD) \
   PLOT_OUTPUT.$(MOD) GAGE_OUTPUT.$(MOD)
	$(F90) $(F90FLAGS) -c $(MAINDEBUG) mass2_main_025.f90

met_data_module.o: met_data_module.f90 TABLE_BOUNDARY_CONDITIONS.$(MOD) \
   DATE_TIME.$(MOD)
MET_DATA_MODULE.$(MOD): met_data_module.o

netcdferror.o: netcdferror.f90

plot_output.o: plot_output.f90 GLOBALS.$(MOD) SCALARS.$(MOD) GAS_FUNCTIONS.$(MOD)
PLOT_OUTPUT.$(MOD): plot_output.o

scalars_module.o: scalars_module.f90
SCALARS.$(MOD): scalars_module.o

table_bc_module.o: table_bc_module.f90 DATE_TIME.$(MOD)
TABLE_BOUNDARY_CONDITIONS.$(MOD): table_bc_module.o

profile_init.o: profile_init.f90 GLOBALS.$(MOD)

clean::
	rm -f ${OBJS}
	rm -f ${MODULES}
	rm -f *~ *% ,*

date_time_test.o: date_time_test.f90 DATE_TIME.$(MOD)

clean::
	rm -rf date_time_test.o

%.o: %.f90
	${COMPILE.f90} $<
tags: TAGS
TAGS: $(SRCS)
	etags $(SRCS)
