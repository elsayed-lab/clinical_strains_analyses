# Introduction

Define, create, and run the analyses used in the paper: ""

This repository contains everything one should need to create a
singularity container which is able to run all of the various R
tasks performed, recreate the raw images used in the figures, create
the various intermediate rda files for sharing with others, etc.  In
addition, one may use the various singularity shell commands to enter
the container and play with the data.

# Installation

Grab a copy of the repository:

```{bash, eval=FALSE}
git pull https://github.com/abelew/clinical_strains_lpanamensis.git
```

The resulting directory should contain a few subdirectories of note:

* local/bin: Contains all the setup scripts used to create the
  container along with the runscript which is run when the container
  is invoked.
* local/etc: A few text files used to help configure the container.
* data/*.Rmd: Numerically sorted R markdown files which contain all the fun
  stuff.  Look here first.
* data/renv*: These are files used by the R package 'renv'.  If one
  wishes, you may recreate the exact versions of everything I used on
  any computer by taking them and doing renv::restore() in an R
  session.  Note that the restore is super-slow.
* data/preprocessing: Archives of the count tables produced when using cyoa
  to process the raw sequence data. Once we have accessions for SRA, I
  will finish the companion container which creates these.
* data/sample_sheets: A series of excel files containing the experimental
  metadata we collected over time.  In some ways, these are the most
  important pieces of this whole thing.
* /versions.txt: A text file containing some version information; the
  debian instance, bioconductor, R, hpgltools, and EuPathDB.

At the root, there should also be a yml and Makefile which contain the
definition of the container and a few shortcuts for
building/running/playing with it.

# Creating the container

With either of the following commands, singularity should read the yml
file and build a Debian stable container with a R environment suitable
for running all of the analyses in data/.

```{bash, eval=FALSE}
make
## Really, this just runs:
sudo -E singularity build target.sif target.yml
## Where 'target' is the name of the actual container specified in the Makefile.
```

The primary meat of the installation is in bootstrap.sh and
bootstrap.R.  Failed package installation messages should appear in
/data/bootstrap.stderr inside the final container image.

# Generating the html/rda/excel output files

One of the neat things about singularity is the fact that one may just
'run' the container and it will execute the commands in its
'%runscript' section.  That runscript should use knitr to render a
html copy of all the Rmd/ files and put a copy of the html outputs
along with all of the various excel/rda/image outputs into the current
working directory of the host system.

```{bash, eval=FALSE}
./tmrc2_analyses.sif
## This should create a new directory prefixed with the current year, month, day, hour, minute
## It should then copy the archived Rmd files, sample sheets, and input data into that location.
## Finally, it should invoke the R built into the container and render the documents to html reports.
## Along the way, that should generate the various output files (xlsx, images, etc) in directories
## with names like 'images', 'excel', etc...
```

# Rendering arbitrary documents to html

The container's runscript accepts some arguments, including '-i' with
a colon separated list of Rmd files.  In this scenario, it should
render whatever Rmd documents provided to html in the current working
directory.

```{bash, eval=FALSE}
./tmrc2_analyses.sif -i test.Rmd
## Wait a couple minutes and hopefully get a test.html (prefixed with the current date).
```

# Playing around inside the container

If, like me, you would rather poke around in the container and watch
it run stuff, either of the following commands should get you there:

All of the fun stuff is in /data.  The container has a working vim and
emacs installation, so go nuts. I also put a portion of my emacs
config sufficient to play with R markdown files.

```{bash, eval=FALSE}
make tmrc2_analyses.overlay
## That makefile target just runs:
mkdir -p tmrc3_analyses_overlay
sudo singularity shell --overlay tmrc3_analyses_overlay tmrc3_analyses.sif

cd /data
emacs -nw 01datasets.Rmd
## Render your own copy of the data:
Rscript -e 'hpgltools::renderme("01datasets.Rmd")'
cp *.html ~/
```

# Pre-built containers

I periodically archive copies of the built containers at:

https://elsayedsingularity.umiacs.io/

Thus, if you are willing to trust that I have not done anything
malicious, you can skip all of the above stuff and try it out.

# Maximum reproducability without the container

The bootstrap script includes a couple invocations from the renv
package and generates the resulting files one would need to recreate
this environment without actually building the container.  Thus, you
may also choose to grab those files out of this repository and just do
renv::restore().

For more information, check out:

https://rstudio.github.io/renv/articles/renv.html

You may notice that I am not actually using renv in the build process,
that something in renv does not play well inside the container
environment and crashes the session.  I am (as of 202405) looking into
this and will hopefully have a solution shortly.

If one chooses this route, one will still need to download the
hpgltools and EuPathDB repositories via git.  In order to get the
exact state of the repository used for the container, check the
/versions.txt file and do a git reset to the appropriate commmit.

# TODO/Administrativia

The container build process installs many more packages than are
actually used in any single analysis because it just grabs the
suggested packages from my DESCRIPTION file.  I therefore would like
instead to send the output from pander to a text file and use that to
define the set of packages to install into the container.

With that in mind, here are the R packages which did not successfully
install into the most recent build:

'rJava', 'venneuler', 'pathfindR'

I am quite confident that they are not needed for this set of
analyses.

The build process is currently excessively verbose.  Every time it passes
and the resulting .sif produces usable reports I am going to remove one
set of outputs and send stderr to a log.
