SHELL=/bin/bash

neci:
	cd dest; ${MAKE} neci.x

new:
	./compile

dbg:
	./compile -d

gneci-cpmd:
	cd dest; ${MAKE} neci-cpmd.a

kneci-cpmd:
	cd kdest; ${MAKE} neci-cpmd.a

neci-cpmd:
	${MAKE} gneci-cpmd
	${MAKE} kneci-cpmd

gneci-vasp:
	cd dest; ${MAKE} neci-vasp.a

kneci-vasp:
	cd kdest; ${MAKE} neci-vasp.a

neci-vasp:
	${MAKE} gneci-vasp
	${MAKE} kneci-vasp

all:
	${MAKE} neci
	${MAKE} neci-cpmd
	${MAKE} neci-vasp

newall:
	${MAKE} new
	${MAKE} neci-cpmd
	${MAKE} neci-vasp

clean:
	cd dest; ${MAKE} clean
	cd kdest; ${MAKE} clean

mkfiles:
	./compile -m

dbgmkfiles:
	./compile -d -m

help:
	@echo -e "make [target]\n\n"\
"Targets:\n"\
"neci		make neci.x.\n"\
"new		make new makefile and clean compile of neci.x.\n"\
"dbg		make new makefile, turn debug flags on and clean compile of neci.x.\n"\
"gneci-cpmd	make neci library for integration with gamma-point version of cpmd.\n"\
"kneci-cpmd	make neci library for integration with k-point version of cpmd.\n"\
"neci-cpmd	make neci libraries for integration with gamma-point and k-point versions of cpmd.\n"\
"gneci-vasp	make neci library for integration with gamma-point version of vasp (currently not implemented in vasp).\n"\
"kneci-vasp	make neci library for integration with k-point version of vasp.\n"\
"neci-vasp	make neci library for integration with gamma-point (currently not implemented in vasp) and k-point versions of vasp.\n"\
"all		make neci.x and all four libraries.\n"\
"newall		produce new makefiles and clean make of neci.x and all four libraries.\n"\
"mkfiles		make new makefiles.\n"\
"dbgmkfiles	make new makefiles with debug flags on.\n"\
"clean		remove all *.f*, *.o, *.mod, *.a and *.x from the dest and kdest subdirectories."
