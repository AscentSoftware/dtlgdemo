FROM rocker/r-ver:4.5.1

RUN apt-get update -y && \
    apt-get install -y libssl-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev \
      libtiff5-dev libjpeg-dev libxml2-dev libcurl4-openssl-dev openssh-server libfontconfig1-dev && \
    rm -rf /var/lib/apt/lists/*

# Enable SSH in Azure
COPY ./.docker/sshd_config /etc/ssh/.
RUN echo "root:Docker!" | chpasswd
RUN ssh-keygen -A


# Set build-time argument
ARG GITHUB_PAT
ENV GITHUB_PAT=${GITHUB_PAT}

# Install renv
RUN R -e "options(renv.config.repos.override = 'https://packagemanager.posit.co/cran/latest')"
RUN R -e "install.packages('remotes')"
RUN R -e "remotes::install_version('renv', '1.1.5')"

RUN mkdir -p /usr/local/lib/R/etc/ /usr/lib/R/etc/
RUN echo "options(renv.config.repos.override = 'https://packagemanager.posit.co/cran/latest')" | \
    tee /usr/local/lib/R/etc/Rprofile.site | \
    tee /usr/lib/R/etc/Rprofile.site

# Install other packages
COPY renv.lock renv.lock
RUN --mount=type=cache,id=renv-cache,target=/root/.cache/R/renv R -e 'renv::restore()'

COPY . ./app/
RUN R -e "remotes::install_local('./app', upgrade = 'never')"

EXPOSE 2222 8080
CMD ["R", "-e", "options(shiny.port = 8080, shiny.host = '0.0.0.0'); library(dtlgdemo); dtlgdemo::run_app()"]
