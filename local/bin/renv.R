#!/usr/bin/env Rscript

## Given recent troubles with RDS-dependent packages, some prerequisite bioconductor packages
## are not currently available in the versions specified.
## As a result, I decided to move this to the maximalist reproducability build possible via renv.
## Sadly, renv has some weaknesses which make this impossible to do completely:
##  1.  It cannot use Ncpus to speed itself up, this by itself is no problem.
##  2.  In the container, once the renv/library tree is activate()d, multiple other functions
##      start failing with a C stack overflow.  Once the renv is deactivate()d, that stops.
##
## Thus, I am going to do the following:
## Use this script to document all the goofy steps I must go through in order to get
## everything working, then use this in the container as the installation script
## as well as provide a renv installer and option to use it.

original_opts <- options(Ncpus=Sys.getenv('CPUS'),
                         timeout=600,
                         repos="https://cloud.r-project.org")

message("Installing renv.")
install.packages("renv")
message("Invoking renv::init().")
renv::init(force = TRUE)
