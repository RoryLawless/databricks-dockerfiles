# Defines a container with dependencies for Bayesian data analysis
# Based on the R Dockerfile provided by Databricks
# URL: https://github.com/databricks/containers/blob/d40d6b0d04dc2c08c6a28f56df19a5c00ad86714/ubuntu/R/Dockerfile
# Installs R 4.6.1 and helpful packages
# Install cmdstan via cmdstanr R package

FROM databricksruntime/minimal:17.3-LTS@sha256:03880bef439fc734f2fe07ebb7dac06a40e77ec81578006d5c66a430099e00b2

# Suppress interactive configuration prompts
ENV DEBIAN_FRONTEND=noninteractive \
    CMDSTAN=/opt/cmdstan

# Install python and virtualenv for Spark and Notebooks
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    python3.12 \
    virtualenv \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install dependencies for R packages
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    libgdal-dev \
    gdal-bin \
    libgeos-dev \
    libproj-dev \
    libsqlite3-dev \
    libssl-dev \
    libudunits2-dev \
    xz-utils \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# We add CRAN's Ubuntu repository to install the latest r-base version.
# The CRAN archive signing key (marutter@gmail.com,
# fingerprint E298A3A825C0D65DFD57CBB651716619E084DAB9) is fetched over HTTPS
# directly from CRAN and installed into a dedicated keyring that is scoped to
# ONLY the CRAN repo via signed-by. This replaces the deprecated apt-key (which
# trusts a key for every repo) and the flaky public keyserver. The repo and key
# are torn down again after R is installed.
# Codename is hardcoded to "noble" to match the pinned Ubuntu 24.04 base (and the
# Posit Package Manager paths below), removing the lsb-release dependency.
ARG R_VERSION=4.6.1-1.2404.0
RUN install -d -m 0755 /etc/apt/keyrings \
  && curl -fsSL https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc \
       | gpg --dearmor -o /etc/apt/keyrings/cran.gpg \
  && gpg --show-keys --with-colons /etc/apt/keyrings/cran.gpg \
       | grep -q E298A3A825C0D65DFD57CBB651716619E084DAB9 \
  && echo "deb [signed-by=/etc/apt/keyrings/cran.gpg] https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" \
       > /etc/apt/sources.list.d/cran.list \
  && apt-get update \
  && apt-get install --yes \
    libssl-dev \
    r-base=${R_VERSION} \
    r-base-dev=${R_VERSION} \
    r-recommended=${R_VERSION} \
  && rm /etc/apt/sources.list.d/cran.list /etc/apt/keyrings/cran.gpg \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# hwriterPlus is used by Databricks to display output in notebook cells
# hwriterPlus is removed for newer version of R, so we hardcode the dependency to archived version
# Rserve allows Spark to communicate with a local R process to run R code
ARG P3M_SNAPSHOT=2026-07-14
RUN Rscript -e "options(repos = c(CRAN = 'https://packagemanager.posit.co/cran/__linux__/noble/${P3M_SNAPSHOT}')); install.packages('pak')" \
 && Rscript -e "options(repos = c(CRAN = 'https://packagemanager.posit.co/cran/__linux__/noble/${P3M_SNAPSHOT}')); pak::pak(c('hwriter', 'TeachingDemos', 'htmltools'))" \
 && Rscript -e "install.packages('https://cran.r-project.org/src/contrib/Archive/hwriterPlus/hwriterPlus_1.0-3.tar.gz', repos=NULL, type='source')" \
 && Rscript -e "options(repos = c(CRAN = 'https://packagemanager.posit.co/cran/__linux__/noble/${P3M_SNAPSHOT}')); pak::pak('Rserve')"
 
# Install project dependencies
RUN Rscript -e "options(repos = c(CRAN = 'https://packagemanager.posit.co/cran/__linux__/noble/${P3M_SNAPSHOT}')); pak::pak(c('data.table', 'sparklyr', 'sf', 'tidyverse', 'brms', 'arcgisutils', 'httr2', 'tinyplot'))" \
 && Rscript -e "options(repos = c(STAN = 'https://stan-dev.r-universe.dev')); install.packages('cmdstanr')"

# Install cmdstan
RUN Rscript -e "library(cmdstanr); dir.create(Sys.getenv('CMDSTAN'), mode = '0755'); cmdstanr::install_cmdstan(dir = Sys.getenv('CMDSTAN'), cores = parallel::detectCores())" \
 && chmod -R a+rX /opt/cmdstan

# Cleanup
RUN Rscript -e "pak::cache_clean()" \
 && rm -rf /tmp/* /var/tmp/* /root/.cache/R

# Initialize the default environment that Spark and notebooks will use
RUN virtualenv -p python3.12 --system-site-packages /databricks/python3
