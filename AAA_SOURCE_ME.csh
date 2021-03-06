# This file used to be called AAA_SOURCE_ME but is largely deprecated
#
# 1a) Source this file in a csh to install and build NEMO from scratch 
# (referred to as the "old manybody method"). This is not to load
# NEMO in your shell, use the nemo_start.csh script for that that
# is produced by this script.
#
# wget ftp://ftp.astro.umd.edu/progs/nemo/nemo_cvs.tar.gz
#
# This script also supports building with the PGPLOT, CFITSIO and HDF4 packages 
# that have to be in NEMO/local to be triggered. 
# Here is an example how to do this:
#
#	cvs -Q co nemo
#	cd nemo
#	mkdir local
#       cd local; cvs -Q co pgplot; cd ..
#       cd local; wget -q ftp://heasarc.gsfc.nasa.gov/software/fitsio/c/cfitsio3006.tar.gz
#       tar zxf cfitsio3006.tar.gz
#       
#       cd ..
#
# after this the install can be done as follows (your shell must be (t)csh !!)
#
#       source AAA_SOURCE_ME
#
# if you see too many problems, clean up, fix your compilers/libraries and restart:
#
#	make distclean          # cleans most of the things created
#	omen                    # remove NEMO* and YAPP* things, cleans the path also
#
#
# Within NEMO there are a few other scripts which have been used to automate
# installations:
#    src/scripts/quickps		(deprecated)
#    src/scripts/bootstrap		(deprecated)
#    src/scripts/test_a_new_nemo_cvs
#
# If you have a current directory with NEMO, you can also use the reuse=1 option in
# the test_a_new_nemo_cvs, e.g.
#    cd nemo_cvs
#    cvs update
#    src/scripts/test_a_new_nemo_cvs   nemo=`pwd`   reuse=1 
#
#
# 25-jul-01  Peter Teuben       created, for MANYBODY
# 18-jan-02  PJT                added optional PGPLOT if detected
#  3-dec-02  PJT                added vogl stuff
#  1-mar-03  PJT                added make_html 
# 17-jun-03  PJT                better path, rehash for immediate use
# 15-oct-03  PJT                added gyfalcON
# 23-mar-04  PJT                for NEMO 3.2 - no more NEMOHOST
# 30-jul-04  PJT                make PGPLOT and CFITSIO optional bootstrappable
# 26-dec-04  PJT       		make HDF optional bootstrappable
# 29-dec-05  PJT                set absolute paths to compilers in makedefs
# 30-jul-06  PJT                various for gh2006 at the beach near Veracruz :-)
# 17-aug-06  PJT                corrected for new falcON procedure
# 31-aug-06  PJT                some png support for pgplot
# 20-mar-07  PJT                comment on gmake vs. make
# 27-jan-12  pjt                deprecate this, use test_a_new_nemo_cvs

# choose make or gmake
set make=make

if ($?NEMO) goto bad_has_nemo

rm -f install.log >& /dev/null
touch install.log

#   number of executables expected on a full successfull install
set nexec=152

#   other options
set png=0

set stat = 0
echo \(Sending output to install.log\)

set copts=()

if (-d local/pgplot) then
  echo "Found a local pgplot, Assuming we're using it"
  set copts=($copts --with-yapp=pgplot --with-pgplot-prefix=`pwd`/lib)
  if ($png) set copts=($copts --enable-png)
  set pgplot=1
else 
  set pgplot=0
endif

if (-e local/cfitsio) then
  echo "Installing from the local cfitsio source"
  set copts=($copts --enable-cfitsio --with-cfitsio-prefix=`pwd`)
  if (! -e include) ln -s inc include
  src/scripts/cfitsio.install >& install.cfitsio.log
endif

if (-e local/hdf) then
  echo "Installing from the local hdf source:"
  ls -l local/hdf
  set copts=($copts --enable-hdf --with-hdf-prefix=`pwd`)
  if (! -e include) ln -s inc include
  src/scripts/hdf.install >& install.hdf.log  
endif

if (1) then
  touch /tmp/nemo_was_here
  mkdir /tmp/NEMO_WAS_HERE
  if ($status) then
    echo "Your filesystem does not support multi-case unique filenames (like A and a)"
    echo "A real Unix depends on it..."
    echo "You probably have a Mac, or use Windows, so, good luck to you"
  endif
  rmdir /tmp/NEMO_WAS_HERE
  rm /tmp/nemo_was_here
endif

#  could temporarily setenv CC,CXX,F77  for configure, but there are really no good defaults...
echo ./configure $copts
./configure $copts >>& install.log

echo Initializing NEMO environment
source nemo_start >>& install.log
echo Postconfig
$make postconfig >>& install.log
source NEMORC.local
if ($pgplot) then
    # other options:   
    $make pgplot PNG=$png >>& install.log
endif

rehash
echo '++++++++++++++++++++++++++++++++++++++++' >>& install.log

echo Building NEMO library 
(cd src; $make -i clean install) >>& install.log
if ($status) then
    @ stat++
endif
rehash
echo '++++++++++++++++++++++++++++++++++++++++' >>& install.log

echo Building html files for all the manual pages
(cd man; ./make_html)  >>& install.log

echo '++++++++++++++++++++++++++++++++++++++++' >>& install.log

echo Building some sample executables by running the testsuite with -b:
echo '   You can later build all executables with "cd $NEMO;make bins"'
echo '   or using "mknemo <program-name>" on a per-case basis'
if (-d CVS) then
  echo "    Since you also seem to have a CVS structure (very good!)"
  echo "    you can also update code directly via CVS, using the -u flag to mknemo:"
  echo '                mknemo -u <programname>'
  echo or
  echo '                mknemo -u -l <programname>'
  echo if the library also needs to be rebuild.
endif

src/scripts/testsuite -b >>& install.log

if (1) then
  # also done in 'make libs', should be done earlier so we can add some Testfile's
  echo Compiling falcON and its tools. 
  (cd usr/dehnen/; $make all)  >& install_falcON.log
endif

if ($stat == 0) then
    echo "Note: Although your current shell now has the NEMO environment loaded,"
    echo "      new shells will not have NEMO pre-loaded. You would need to add"
    echo "      the following command/alias to your .cshrc (or equivalent) file:"
    echo "                   source $NEMO/nemo_start"
    rehash
else
    echo Install failed: stat = $stat
endif


set n1=(`grep TESTSUITE: install.log | grep -v OK | wc -l`)
set n2=(`grep TESTSUITE: install.log | wc -l`)
set n3=(`ls bin|wc -l`)

echo "Found $n3 executables ($nexec at last count)"
echo "Found $n1/$n2 problems with the TESTSUITE"
if ($n1 > 0) then
  grep TESTSUITE: install.log | grep -v OK 
endif

# kludged sh support 

if (! -e nemo_start.csh) ln -s nemo_start nemo_start.csh
src/scripts/mk_nemo_start.sh >  nemo_start.sh

goto end
#
bad_has_nemo:
  echo "NEMO=$NEMO already exists, AAA_SOURCE_ME should be run from a clean place"
  echo "use the alias 'omen' to remove the NEMO environment"
  goto end


end:
   echo "All done."

