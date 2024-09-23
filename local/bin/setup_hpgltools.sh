#!/usr/bin/env bash
export HOME=/data

echo "Setting up a Debian stable instance."
source /versions.sh
apt-get update 1>/dev/null
apt-get -y upgrade 1>/dev/null
apt-get -y install $(/bin/cat /usr/local/etc/packages.txt) 1>/dev/null
apt-get clean

## Set up a starter modules tree
mkdir -p "/sw/local/conda/${CONTAINER_VERSION}" /sw/modules/conda
cp /sw/modules/template "/sw/modules/conda/${CONTAINER_VERSION}"

start=$(pwd)
#commit="b26529d25251c3d915b718460ef34194dbf8e418"
log=/setup_hpgltools.stdout
err=/setup_hpgltools.stderr
prefix="/sw/local/conda/${CONTAINER_VERSION}"
## I know one shouldn't use cat | grep, but I don't trust the proc filesystem to act like a file.
cpus=$(cat /proc/cpuinfo | grep -c processor)
echo "Starting setup_hpgltools, downloading required headers and utilities." | tee -a ${log}

echo "Installing mamba with hpgltools env to ${prefix}." | tee -a ${log}
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -axj bin/micromamba 2>/dev/null 1>&2
echo "Creating hpgltools conda environment." | tee -a ${log}
micromamba --root-prefix="${prefix}" --yes create -n hpgltools \
           glpk imagemagick mpfr netcdf4 pandoc r-base=${R_VERSION} \
           -c conda-forge 2>/dev/null 1>&2
export MAMBA_EXE='/bin/micromamba';
export MAMBA_ROOT_PREFIX="/sw/local/conda/${CONTAINER_VERSION}";
__mamba_setup="$("$MAMBA_EXE" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX" 2>/dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias micromamba="$MAMBA_EXE"  # Fallback on help from mamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<
echo "Activating hpgltools environment." | tee -a ${log}
micromamba activate hpgltools

## Setup renv and initialize my package versions.
echo "options(Ncpus=${CPUS})" > "${HOME}/.Rprofile"
echo "options(timeout=600)" >> "${HOME}/.Rprofile"
echo "options(repos='https://cloud.r-project.org')" >> "${HOME}/.Rprofile"

export R_LIBS_USER=


#echo "Cloning the hpgltools repository." | tee -a ${log}
#git clone https://github.com/abelew/hpgltools.git 1>>${log} 2>>${err}
#cd hpgltools || exit
##export HPGL_VERSION=$(git log -1 --date=iso | grep ^Date | awk '{print $2}' | sed 's/\-//g')
##echo "export HPGL_VERSION=${HPGL_VERSION}" >> /versions.sh
#echo "The last commit included:" | tee -a ${log}
#git log -1 | tee -a ${log}
#
#if [[ -n "${HPGLTOOLS_COMMIT}" ]]; then
##    echo "Explicitly setting to the commit: ${HPGLTOOLS_COMMIT}."
#    git reset "${HPGLTOOLS_COMMIT}" --hard
#else
#    echo "Using the current HEAD of the hpgltools repository: ${HPGL_VERSION}."
#fi
#
### It turns out I cannot allow R to install the newest bioconductor version arbitrarily because
### not every package gets checked immediately, this caused everything to explode!
#echo "Installing bioconductor version ${BIOC_VERSION}."
#Rscript -e "install.packages('BiocManager')" 2>/dev/null 1>&2
#Rscript -e "BiocManager::install(version='${BIOC_VERSION}', ask=FALSE)" 2>/dev/null 1>&2
#
#echo "Installing non-base R prerequisites, essentially tidyverse." | tee -a ${log}
#Rscript -e "BiocManager::install(c('devtools', 'tidyverse'), force=TRUE, update=TRUE, ask=FALSE)" 2>/dev/null 1>&2
#
### 20240501 FIXME:
### The new R/bioconductor (4.4.0/3.19) release has mysteriously broken the existing release
### in some ways which are quite troubling (4.3.3/3.18), my current guess/assumption
### is that this is in response to the recent security vulnerability uncovered in the RDS format.
### Whatever the cause, the existing versions of some important packages no longer install.
### The following lines are my attempt to circumvent this problem.
### The main thing I want is AnnotationHubData, but for that I require Matrix, S4Arrays, MASS,
### and maybe others?  I think that, ASAP the following lines should be removed.
#Rscript -e "remotes::install_url('https://github.com/cran/Matrix/archive/refs/tags/1.6-5.tar.gz')" 2>/dev/null 1>&2
#Rscript -e "remotes::install_url('https://cran.r-project.org/src/contrib/Archive/MASS/MASS_7.3-60.tar.gz')" 2>/dev/null 1>&2
#Rscript -e "devtools::install_github('Bioconductor/AnnotationHubData')" 2>/dev/null 1>&2
#
### In the process of getting the above two things to install, I discovered that bioc version 3.17
### does not appear to have these problems; so I changed the container yml definition to go back
### to that release.
#
#echo "Installing hpgltools dependencies with devtools." | tee -a ${log}
#Rscript -e 'devtools::install_dev_deps(".", dependencies = "Depends")' 2>/dev/null 1>&2
#Rscript -e 'devtools::install_dev_deps(".", dependencies = "Imports")' 2>/dev/null 1>&2
#Rscript -e 'devtools::install_dev_deps(".", dependencies = "Suggests")' 2>/dev/null 1>&2
#
### preprocessCore has a bug which is triggered from within containers...
### https://github.com/Bioconductor/bioconductor_docker/issues/22
#echo "Installing preprocessCore without threading to get around a container-specific bug." | tee -a ${log}
#Rscript -e "BiocManager::install('preprocessCore', configure.args=c(preprocessCore='--disable-threading'), ask=FALSE, force=TRUE, update=TRUE, type='source')" 2>/dev/null 1>&2
#
### It appears the ggtree package is having troubles...
#echo "Installing a dev version of ggtree due to weirdo errors, this is super annoying." | tee -a ${log}
#Rscript -e 'remotes::install_github("YuLab-SMU/ggtree")' 2>/dev/null 1>&2
#echo "In my last revision I got weird clusterProfiler loading errors, testing it out here." | tee -a ${log}
#Rscript -e 'BiocManager::install(c("DOSE", "clusterProfiler"), force=TRUE, update=TRUE, ask=FALSE)' 2>/dev/null 1>&2
#
### I like these sankey plots and vennerable, but they are not in bioconductor.
#echo "Installing ggsankey and vennerable." | tee -a ${log}
#Rscript -e 'devtools::install_github("davidsjoberg/ggsankey")' 1>/dev/null 2>&1
#Rscript -e 'devtools::install_github("js229/Vennerable")' 1>/dev/null 2>&1
### The new version of dbplyr is broken and causes my annotation download to fail, and therefore _everything_ else.
### Rscript -e 'devtools::install_version("dbplyr", version="2.3.4", repos="http://cran.us.r-project.org")' 1>/dev/null 2>&1
#
##echo "Updating packages to the current bioconductor release." | tee -a ${log}
#Rscript -e 'BiocManager::install(force=TRUE, update=TRUE, ask=FALSE)' 2>/dev/null 1>&2
#
#echo "Installing hpgltools itself." | tee -a ${log}
#R CMD INSTALL . 2>/dev/null 1>&2
#cd $start || exit
#
### Adding a few random packages used for rendering the ML classifier document.
#Rscript -e 'BiocManager::install(c("CorLevelPlot", "flashClust", "glmnet", "irr", "ranger", "xgboost"), force=TRUE, update=TRUE, ask=FALSE)' 2>/dev/null 1>&2
#
#git clone https://github.com/abelew/EuPathDB.git 2>/dev/null 1>&2
#cd EuPathDB || exit
#export EUPATHDB_VERSION=$(git log -1 --date=iso | grep ^Date | awk '{print $2}' | sed 's/\-//g')
#echo "export EUPATHDB_VERSION=${EUPATHDB_VERSION}" >> /versions.sh
#echo "Installing EuPathDB packages from Depends via devtools." | tee -a ${log}
#Rscript -e 'devtools::install_dev_deps(".", dependencies="Depends")' 2>/dev/null 1>&2
#echo "Installing EuPathDB packages from Imports via devtools." | tee -a ${log}
#Rscript -e 'devtools::install_dev_deps(".", dependencies="Imports")' 2>/dev/null 1>&2
#echo "Installing EuPathDB packages from Suggests via devtools." | tee -a ${log}
#Rscript -e 'devtools::install_dev_deps(".", dependencies="Suggests")' 2>/dev/null 1>&2
#R CMD INSTALL . 2>/dev/null 1>&2
#cd $start || exit
#
#echo "Installing a Leishmania panamensis annotation package." | tee -a ${log}
######Rscript -e 'library(EuPathDB); meta <- download_eupath_metadata(webservice="tritrypdb"); panamensis_entry <- get_eupath_entry("MHOM", metadata=meta[["valid"]]); panamensis_db <- make_eupath_orgdb(panamensis_entry)' 2>dev/null 1>&2
