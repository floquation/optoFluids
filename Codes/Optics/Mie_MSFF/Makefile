#$preamble
#
# Script initially inspired by:
# http://www.webalice.it/o.drofa/davide/makefile-fortran/makefile-fortran.html
#  
#
# This makefile works with the GNU 'make' command, the one found on
# GNU/Linux systems and often called gmake on non-GNU systems.
#
#
#
#
# A simple hand-made makefile, optionally allowing to use different directories for SRC/BIN/MOD/OBJS.
#   Subdirectories are not supported.
# Created and tested using the gfortran 4.9.2 version. My settings are:
#   I use a separate src, obj and mod directory, while the binaries/executables go into the current directory.
#   I use the .f90 extention for my sources, .o for my objects and .mod for my module files. Binaries have no extention.
# - Kevin van As, MSc Student TU Delft, Department of Chemical Engineering, Transport Phenomena group
#
#
#
#
#			DISCLAIMER:
#	YOU ARE RESPONSIBLE FOR BACKING UP YOUR OWN CODE
#	THE PRESENT MAKEFILE HAS BEEN TESTED FOR MY PREFERED SETTINGS,
#	BUT I CAN NOT, AND WILL NOT, GUARANTEE THAT IT WORKS FOR ALL POSSIBLE SETTINGS.
#	CONSEQUENTLY, I TAKE NO RESPONSBILITY FOR THE EVENTUAL CORRUPTION OF YOUR CODE.
#	(Although I don't know how that'd possibly happen... - just make back-ups!)
#	THE USER IS OBLIGED TO BACK-UP ITS OWN CODE, BEFORE USING THIS MAKEFILE.
#
#
#			NOTES:
#	- The script MUST BE called from the directory in which it is contained. So 'cd' to that directory before calling it.
#	- This makefile requires that in the dependencies the source file is listed FIRST for both the object and module file
#	  Using 'make depend', this is automatically satisfied **for my version of gfortran**.
#
#			USAGE:
#	- Getting Started
#	  (1a) Set the appropriate directories to your names (e.g.: src/bin/objs/mods).
#	  (1b) Choose your extentions (e.g.: .f90/.o/.mod).
#	  (1c) Set the appropriate compiler and compiler flags.
#	  (2)  Edit the PROGRAMS variable to list all your executables.
#	  (3)  List all your object files in the ALLOBJECTS variable. This is required for linking.
#	- Compiling/Linking:
#	  (4)  Call 'make depend' whenever your dependencies have to be regenerated
#	  (5)  Call 'make' to compile & link your code, generating the binaries/executables
#	  (6)  Use 'make clean' or 'make veryclean' to be able to start compiling from a clean workspace
#
# ======================================================================
# PWDs Variables
# ======================================================================
#
# Use "." to not use a separate directory for the given files:
# WARNING: You might want to run 'make veryclean' before changing these,
#          as it will affect the cleaning behaviour as well!
# WARNING: Do NOT append the names with spacebars/tabs: you are asking for trouble.
# Source code-directory 				= e.g. .f90/.F90 files ($(EXT_SRC)):
SRCDIR = src
# Compiled (object) directory 			= e.g. .o files ($(EXT_OBJ)):
OBJDIR = objs
# Compiled headers (modules) directory 	= e.g. .mod files ($(EXT_MOD)):
MODDIR = mods
# Directory for the created executables:
BINDIR = .

# The directory (absolute path) in which this Makefile is contained:
ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
MKFILE := $(firstword $(MAKEFILE_LIST))

# For the validator:
#BHMIE_PWD = $(ROOT_DIR)/../../Codes_downloaded/BohrenHuffmanMie_F90

# ======================================================================
# 
# Let's start with the declarations (flags etc.)
#
# ======================================================================

# The compiler
#FC = gfortran-5.3.0
FC = gfortran-4.9.2

# flags for debugging or for maximum performance, comment as necessary

# Here the -O# gives the level of compiler optimizations. O3 is highest and does all kinds of stuff. O2 is slightly safer. O is safest but slowest. Original value was: O2
# The fbounds-check adds some array bounds checking capabilities to the compiler. Soothes the wounds of segmentation-faults.
# FCFLAGS += -g -fbounds-check
# FCFLAGS += -O -fbounds-check
# FCFLAGS += -O2 -fbounds-check
FCFLAGS += -O3 -fbounds-check

# Give all warnings flag
#FCFLAGS += -Wall

# Free-form syntax is used for my code. Required for gcc>5
#FCFLAGS += -ffree-form -ffree-line-length-0

#this flag enables the use of gprof command to profile. Usage after normal execution: gprof [programbinary] gmon.out > filename, to output profile to "filename"
#FCFLAGS += -pg

# flags forall (e.g. look for system .mod files, required in gfortran)
FCFLAGS +=	-I/usr/include #\

#		-I$(BHMIE_PWD)

# libraries needed for linking
#LDFLAGS += -L$(BHMIE_PWD)
#LDFLAGS += -lbhmie
#LDFLAGS += --verbose

# Extensions
EXT_SRC = f90
EXT_OBJ = o
EXT_MOD = mod
EXT_OUT = .out #Include the dot for this one! ".out", not "out"

# List of executables to be built within the package (prepend "$(BINDIR)/" to each!)
PROGRAMS = $(BINDIR)/mybhmie_start $(BINDIR)/MieAlgorithmFF_start $(BINDIR)/scatteringMatrixPlotter
# List of all objects to be used by all programs (prepend "$(OBJDIR)/" to each and append ".$(EXT_OBJ)")
ALLOBJECTS = $(OBJDIR)/class_SphereManager.o $(OBJDIR)/class_Camera.o $(OBJDIR)/class_Sphere.o $(OBJDIR)/mybhmie.o $(OBJDIR)/booleanFunctions.o $(OBJDIR)/mymath.o $(OBJDIR)/iomod.o $(OBJDIR)/DEBUG.o $(OBJDIR)/MieAlgorithmFF.o $(OBJDIR)/mytimer.o $(OBJDIR)/classes_ScatterStrategies.o $(OBJDIR)/class_ScatterActuator.o
#ALLOBJECTS = $(OBJDIR/*.o)

#$intro
# "make" builds all
all: $(PROGRAMS)
	for file in $(PROGRAMS) ; do \
		mv "$$file" "$$file"$(EXT_OUT); \
	done

# ======================================================================
# 
# Rules for building (dependencies)
#
# (WARNING: Be careful to prepend the appropriate path variable!)
#
# --> Note that using verbose dependencies (listing dependencies which aren't
# dependencies of the target), will not cause any error. For big projects,
# however, it will cause excessive re-compilation of code which needs not
# be recompiled. The latter occurs when one of the verbose dependencies is
# modified (and thus the Makefile concludes that the target needs recompilation),
# whereas the target does not depend on the file you modified. For small projects,
# this is not a problem. Consequently, for ease, you could make everything depend
# on everything, such that you need not track the dependencies yourself.
# --> The opposite, using too few dependencies, will raise errors if 'make' is
# called from a clean state (typically "undefined reference to" or
# "Can't open module file ..."). If 'make' is called from a state in which
# the forgotten dependencies already exist, then no error will be raised.
# However, if you change those forgotten dependencies, the Makefile will not
# recompile them, since they are not listed as dependencies.
#
# ======================================================================

#$(OBJDIR)/mybhmie_start.o: $(MODDIR)/mybhmie.mod

#$(OBJDIR)/MieAlgorithmFF.o: $(MODDIR)/class_SphereManager.mod $(MODDIR)/class_Camera.mod $(MODDIR)/iomod.mod $(MODDIR)/mybhmie.mod $(MODDIR)/mymath.mod

#$(OBJDIR)/class_SphereManager.o: $(MODDIR)/class_Sphere.mod

#$(OBJDIR)/validator.o: $(MODDIR)/mybhmie.mod $(MODDIR)/booleanFunctions.mod

#$conclusion
#
#
#
# ======================================================================
# And now the general rules, these should NOT require MODIFIcation
# ======================================================================
#
#
#

# Make all programs require all objects for linking
# Advantage: Saves my precious time, because I need not carefully select the required object files for each executable.
# Disadvantange: Increases the executable size by including unnecessary files. This is generally not a problem, as a single Makefile should not be used for creating significantly different executables.
$(PROGRAMS): $(ALLOBJECTS)

# Create temp. directories
ifneq ($(OBJDIR),.) # Only if OBJDIR is not the current directory.
$(OBJDIR):
	mkdir -p $(OBJDIR)
endif

ifneq ($(MODDIR),.) # Only if MODDIR is not the current directory.
$(MODDIR):
	mkdir -p $(MODDIR)
endif

ifneq ($(BINDIR),.) # Only if BINDIR is not the current directory.
$(BINDIR):
	mkdir -p $(BINDIR)
endif

# General rule for building prog from prog.o; $^ (GNU extension) is
# used in order to list additional object files on which the
# executable depends
# $@ lists the target itself.
# The % is a wildcard.
$(BINDIR)/%: $(OBJDIR)/%.$(EXT_OBJ) | $(BINDIR) 
	$(FC) $(FCFLAGS) -o $@ $^ $(LDFLAGS)

# General rule for building a .mod file.
# These are automatically generated when the .o file is generated, so by making
# the .mod dependent on the .o, they are automatically generated.
#  This has been done in the autodependency generation.
# The rule below is to tell 'make' that we are updating the module file.
#  If this is not done, files dependent on the module will not think the module gets updated (even though it has been updated),
#  and consequently conclude that they need not be rebuild, whereas they DO need to be rebuild.
$(MODDIR)/%.mod:
	
#	echo "generated mod $@"
#     Note: There is a "TAB" on the line above this line, which is for-some-reason OBLIGATORY!
#     Otherwise an error occurs: "no rule to make target `mod_dir/*.mod' ..."

# Generates the module file and the object file, but no location is specified for the object file.
#  Consequently, will throw the object file in your cwd...
#   NOTE: This only works of the source file is first in the list of dependencies!
#$(MODDIR)/%.mod:
#	echo "I am = $@"
#	$(FC) $(FCFLAGS) -c $< -J$(MODDIR)

# The rule below allows for generating both the module and object file.
#   NOTE: This only works of the source file is first in the list of dependencies!
#$(MODDIR)/%.$(EXT_MOD) $(OBJDIR)/%.$(EXT_OBJ):
#	echo "SRCfile = $<"
#	echo "SRCfile2OBJfile = `echo $< | sed 's/$(SRCDIR)\//$(OBJDIR)\//g' | sed 's/\.$(EXT_SRC)/\.$(EXT_OBJ)/g'`"
#	if [ "`echo $< | sed 's/$(SRCDIR)\//$(OBJDIR)\//g' | sed 's/\.$(EXT_SRC)/\.$(EXT_OBJ)/g'`" == "$<" ]; then \
#	    echo " --- ERROR --- Trying to overwrite the source file. Did you specify the correct SRC/OBJ extention and directory in your Makefile?"; \
#	    EXIT_FATAL_ERROR_commandDoesNotExistButThisDoesTerminateTheMake; \
#	else \
#	    $(FC) $(FCFLAGS) -c $< -J$(MODDIR) -o "`echo $< | sed 's/$(SRCDIR)\//$(OBJDIR)\//g' | sed 's/\.$(EXT_SRC)/\.$(EXT_OBJ)/g'`"; \
#	fi

# Use the precompiler to generate a module file WITHOUT the object file:
#   NOTE: This only works of the source file is first in the list of dependencies!
#$(MODDIR)/%.$(EXT_MOD):
#	$(FC) $(FCFLAGS) -cpp -MM $< -J$(MODDIR) > /dev/null

# General rules for building prog.o from prog.f90 or prog.F90; $< is
# used in order to list only the first prerequisite (the source file)
# and not the additional prerequisites such as module or include files
$(OBJDIR)/%.$(EXT_OBJ): $(SRCDIR)/%.$(EXT_SRC) | $(OBJDIR) $(MODDIR)
	$(FC) $(FCFLAGS) -c $< -o $@ -J$(MODDIR)

# Utility targets
.PHONY: clean veryclean depend depend1 all

#  Clean with "cannot remove current directory", hence the if statement.
#  Also checks whether the directory is empty.
#   This prevents removing the directory if e.g. SRCDIR==MODDIR.
clean:
#	[ "$(ls -A /path/to/directory)" ] && echo "Not Empty" || echo "Empty"
	rm -f $(OBJDIR)/*.$(EXT_OBJ)
	rm -f $(MODDIR)/*.$(EXT_MOD)
	rm ./.depend
ifneq ($(OBJDIR),.) # Only if OBJDIR is not the current directory.
	[ -d $(OBJDIR) ] && [ "`ls -A $(OBJDIR)`" ] && echo "$(OBJDIR) Not Empty" || rm -rf $(OBJDIR);
endif
ifneq ($(MODDIR),.) # Only if MODDIR is not the current directory.
	[ -d $(MODDIR) ] && [ "`ls -A $(MODDIR)`" ] && echo "$(MODDIR) Not Empty" || rm -rf $(MODDIR);
endif
	echo ""; echo "	<< '.$(EXT_OBJ)' and '.$(EXT_MOD)' files have been removed. Use 'make veryclean' to remove the executables as well >>"; echo "";

veryclean: clean
	rm -f *~
	rm -f $(SRCDIR)/*~
	rm -f $(PROGRAMS)
ifneq ($(BINDIR),.) # Only if BINDIR is not the current directory.
	[ -d $(BINDIR) ] && [ "`ls -A $(BINDIR)`" ] && echo "$(BINDIR) Not Empty" || rm -rf $(BINDIR);
endif

# Generate the dependencies using gfortran's preprocessor.
#  Since this requires module files which are not yet generated, this is bound to give errors.
#   The cause of this problem is that the files are not listed in the appropriate order (alphabetic instead of top-down)
#  If we do however repeat 'make depend', this will work after up to #SourceFiles iterations.
# PROBLEM with this method: If there is a compilation issue, an infinite loop will occur which should be manually cancelled using Cntrl+C.
#  SEMI-SOLUTION: Use "make depend1" to view the one compilation error instead of a spam of repeated compilation errors.
#
# The 1st 'sed' operation appends the $OBJDIR. $MODDIR and $SRCDIR are already automatically added by gfortran.
# The 2nd 'grep|sed|sed' is meant to make all module files depend on their object files.
#  This works under the assumption that the module and object are on ONE LINE (cannot work with the \-continuation sign)
#  and the object is listed right before the module file. Both these conditions are satisfied by my gfortran compiler.
depend: $(SRCDIR)/*.$(EXT_SRC) | $(MODDIR)
	rm -f ./.depend
	$(FC) $(FCFLAGS) -cpp -MM $^ -J$(MODDIR) >> ./.depend && (\
	    sed -i -e "s/\S\+\.$(EXT_OBJ)/$(OBJDIR)\/&/g" .depend; \
	    grep "^objs/\S\+\.o\s" .depend | sed "s/:.*$$//g" | sed -r "s/(objs\/\S+\.o)\s(mods\/\S+\.mod)/\2: \1/g" >> .depend; \
	    echo; echo "  --- SUCCESS --- Despite any errors above, dependencies have successfully been generated!"; echo;) || \
	    (echo "   --- Make depend failed by prereq. order. Executing make depend iteratively. ---"; \
		make depend -f $(MKFILE) --no-print-directory)

# Same as depend, but now performs only one iteration.
depend1: $(SRCDIR)/*.$(EXT_SRC) | $(MODDIR)
	rm -f ./.depend
	$(FC) $(FCFLAGS) -cpp -MM $^ -J$(MODDIR) >> ./.depend
	sed -i -e "s/\S\+\.$(EXT_OBJ)/$(OBJDIR)\/&/g" .depend
	grep "^objs/\S\+\.o\s" .depend | sed "s/:.*$$//g" | sed -r "s/(objs\/\S+\.o)\s(mods\/\S+\.mod)/\2: \1/g" >> .depend


-include .depend


# EOF: Makefile
