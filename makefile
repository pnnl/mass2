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
# Last Change: Wed Feb 28 14:59:04 2001 by William A. Perkins <perk@dora.pnl.gov>
# -------------------------------------------------------------
# $Id$

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
DEBUG =  -O
FLAGS = $(NETCDFFLAGS) $(DEBUG) -TARG:platform=IP30  -OPT:Olimit=0 

# general compile/link flags

MAINDEBUG = $(DEBUG)
F90FLAGS = $(FLAGS)
LIBLOC = 
LDFLAGS = $(NETCDFLDFLAGS) ${LIBLOC} $(FLAGS)
LIBS = $(NETCDFLIBS) -lfpe

TARGET = mass2_v027
SRCS =											\
     julian.f90									\
     date_time_module.f90						\
     gas_coeffs_module.f90						\
     gas_functions_module.f90					\
     scalars_module.f90							\
     energy_flux_module.f90						\
     gage_output_module.f90						\
     plot_output.f90							\
     netcdferror.f90							\
     global_module_023.f90						\
     io_routines_module.f90						\
     table_bc_module.f90						\
     block_bc_module.f90						\
     met_data_module.f90						\
     profile_init.f90							\
     misc_vars_module.f90						\
     transport_only_module.f90					\
     mass2_main_025.f90							\
     mass2.f90									\
	 scalars_source.f90							\
	 temperature_source.f90						\
	 tdg_source.f90								\
	 generic_source.f90							\
	 bed_source.f90								\
	 biota_source.f90							\
	 biota.f90									\
	 sediment_source.f90						\
	 particulate_source.f90						\
	 bed.f90									\
	 bed_functions.f90							\
	 accumulator.f90							\
	 total_conc.f90

OBJS = $(SRCS:%.f90=%.o)

MODULES =										\
    BLOCK_BOUNDARY_CONDITIONS.$(MOD)			\
    DATE_TIME.$(MOD)							\
    ENERGY_FLUX.$(MOD)							\
    F90_UNIX_PROC.$(MOD)						\
    GAGE_OUTPUT.$(MOD)							\
    GAS_COEFFS.$(MOD)							\
    GAS_FUNCTIONS.$(MOD)						\
    GLOBALS.$(MOD)								\
    IO_ROUTINES_MODULE.$(MOD)					\
    JULIAN.$(MOD)								\
    MET_DATA_MODULE.$(MOD)						\
    PLOT_OUTPUT.$(MOD)							\
    SCALARS.$(MOD)								\
    TABLE_BOUNDARY_CONDITIONS.$(MOD)			\
    MISC_VARS.$(MOD)							\
    TRANSPORT_ONLY.$(MOD)						\
    MASS2_MAIN_025.$(MOD)						\
    SCALARS_SOURCE.$(MOD)						\
	TEMPERATURE_SOURCE.$(MOD)					\
	TDG_SOURCE.$(MOD)							\
	GENERIC_SOURCE.$(MOD)						\
	BED_SOURCE.$(MOD)							\
	BIOTA_CALL_MOD.$(MOD)						\
	BIOTA_ERRORS_MOD.$(MOD)						\
	BIOTA_IDEN_MOD.$(MOD)						\
	BIOTA_MOD.$(MOD)							\
	BIOTA_QA_MOD.$(MOD)							\
	BIOTA_SOURCE_MODULE.$(MOD)					\
	RDBLK_MOD.$(MOD)							\
	SEDIMENT_SOURCE.$(MOD)  					\
	PARTICULATE_SOURCE.$(MOD)					\
	BED_MODULE.$(MOD) 							\
	ACCUMULATOR.$(MOD)

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

accumulator.o: accumulator.f90 GLOBALS.$(MOD) SCALARS.$(MOD) \
	SCALARS_SOURCE.$(MOD) MISC_VARS.$(MOD) DATE_TIME.$(MOD)
ACCUMULATOR.$(MOD): accumulator.o

bed.o: bed.f90 SCALARS_SOURCE.$(MOD) SCALARS.$(MOD) GLOBALS.$(MOD) \
	MISC_VARS.$(MOD)
BED_MODULE.$(MOD): bed.o

bed_functions.o: bed_functions.f90 BED_MODULE.$(MOD)

bed_source.o: bed_source.f90 TABLE_BOUNDARY_CONDITIONS.$(MOD) \
	GLOBALS.$(MOD) MISC_VARS.$(MOD)
BED_SOURCE.$(MOD): bed_source.o

biota.o: biota.f90
BIOTA_CALL_MOD.$(MOD) BIOTA_ERRORS_MOD.$(MOD) BIOTA_IDEN_MOD.$(MOD) \
    BIOTA_MOD.$(MOD) BIOTA_QA_MOD.$(MOD) RDBLK_MOD.$(MOD): biota.o

biota_source.o: biota_source.f90 BIOTA_MOD.$(MOD) \
	MISC_VARS.$(MOD) GLOBALS.$(MOD) JULIAN.$(MOD)
BIOTA_SOURCE_MODULE.$(MOD): biota_source.o

block_bc_module.o: block_bc_module.f90 \
		TABLE_BOUNDARY_CONDITIONS.$(MOD)
BLOCK_BOUNDARY_CONDITIONS.$(MOD): block_bc_module.o

date_time_module.o: date_time_module.f90 JULIAN.$(MOD)
DATE_TIME.$(MOD): date_time_module.o

energy_flux_module.o: energy_flux_module.f90
ENERGY_FLUX.$(MOD): energy_flux_module.o

gage_output_module.o: gage_output_module.f90 GLOBALS.$(MOD) \
	SCALARS.$(MOD) SCALARS_SOURCE.$(MOD) GAS_FUNCTIONS.$(MOD) \
	DATE_TIME.$(MOD) BED_MODULE.$(MOD)
GAGE_OUTPUT.$(MOD): gage_output_module.o

gas_coeffs_module.o: gas_coeffs_module.f90
GAS_COEFFS.$(MOD): gas_coeffs_module.o

gas_functions_module.o: gas_functions_module.f90 GAS_COEFFS.$(MOD)
GAS_FUNCTIONS.$(MOD): gas_functions_module.o

generic_source.o: generic_source.f90 MISC_VARS.$(MOD) BED_SOURCE.$(MOD)
GENERIC_SOURCE.$(MOD): generic_source.o

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
   PLOT_OUTPUT.$(MOD) GAGE_OUTPUT.$(MOD) MISC_VARS.$(MOD) TRANSPORT_ONLY.$(MOD) \
   SCALARS_SOURCE.$(MOD)  BED_MODULE.$(MOD) ACCUMULATOR.$(MOD)
	$(F90) $(F90FLAGS) -c $(MAINDEBUG) mass2_main_025.f90
MASS2_MAIN_025.$(MOD): mass2_main_025.o

mass2.o: mass2.f90 \
	MASS2_MAIN_025.$(MOD)
	$(F90) $(F90FLAGS) -c $(MAINDEBUG) mass2.f90

met_data_module.o: met_data_module.f90 TABLE_BOUNDARY_CONDITIONS.$(MOD) \
   DATE_TIME.$(MOD)
MET_DATA_MODULE.$(MOD): met_data_module.o

misc_vars_module.o: misc_vars_module.f90
MISC_VARS.$(MOD): misc_vars_module.o

netcdferror.o: netcdferror.f90

particulate_source.o: particulate_source.f90  GLOBALS.$(MOD) SCALARS.$(MOD) \
	MISC_VARS.$(MOD) bed_functions.inc
PARTICULATE_SOURCE.$(MOD): particulate_source.o

plot_output.o: plot_output.f90 GLOBALS.$(MOD) SCALARS.$(MOD) SCALARS_SOURCE.$(MOD) \
	GAS_FUNCTIONS.$(MOD) BED_MODULE.$(MOD) MISC_VARS.$(MOD) ACCUMULATOR.$(MOD)
PLOT_OUTPUT.$(MOD): plot_output.o

scalars_module.o: scalars_module.f90
SCALARS.$(MOD): scalars_module.o

scalars_source.o: scalars_source.f90 TEMPERATURE_SOURCE.$(MOD) TDG_SOURCE.$(MOD) \
	GENERIC_SOURCE.$(MOD) SCALARS.$(MOD) MET_DATA_MODULE.$(MOD) BIOTA_SOURCE_MODULE.$(MOD) \
	BIOTA_MOD.$(MOD) SEDIMENT_SOURCE.$(MOD) PARTICULATE_SOURCE.$(MOD)
SCALARS_SOURCE.$(MOD): scalars_source.o

sediment_source.o: sediment_source.f90 GLOBALS.$(MOD) SCALARS.$(MOD) MISC_VARS.$(MOD)
SEDIMENT_SOURCE.$(MOD): sediment_source.o

table_bc_module.o: table_bc_module.f90 DATE_TIME.$(MOD)
TABLE_BOUNDARY_CONDITIONS.$(MOD): table_bc_module.o

tdg_source.o: tdg_source.f90 MISC_VARS.$(MOD) GAS_FUNCTIONS.$(MOD) \
	MET_DATA_MODULE.$(MOD)
TDG_SOURCE.$(MOD): tdg_source.o

temperature_source.o: temperature_source.f90 MET_DATA_MODULE.$(MOD) \
	MISC_VARS.$(MOD) ENERGY_FLUX.$(MOD)
TEMPERATURE_SOURCE.$(MOD): temperature_source.o

transport_only_module.o: transport_only_module.f90 DATE_TIME.$(MOD) GLOBALS.$(MOD)
TRANSPORT_ONLY.$(MOD): transport_only_module.o

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
