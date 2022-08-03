# syntax=docker/dockerfile:1
FROM ubuntu:22.04
ENV NODE_VERSION 15.2.1

# Set debconf to run non-interactively
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Install development dependencies (get purged after the build)
RUN apt-get update && apt-get install -y -q --no-install-recommends \
        apt-transport-https \
        build-essential \
        ca-certificates \
        software-properties-common \
        curl \
        git \
        libssl-dev \
        wget \
        libfontconfig \ 
        libcairo2-dev \
        libpango1.0-dev \
        libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*


# Install nvm with node and npm
SHELL ["/bin/bash", "--login", "-i", "-c"]
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash
RUN source /root/.bashrc && nvm install $NODE_VERSION
SHELL ["/bin/bash", "--login", "-c"]
# setup path to use node for the rest of the dockerfile
ENV PATH /root/.nvm/versions/node/v$NODE_VERSION/bin:$PATH

# install racket (snipped from: https://github.com/jackfirth/racket-docker/blob/master/racket.Dockerfile)
RUN curl --retry 5 -Ls "https://download.racket-lang.org/installers/8.5/racket-8.5-x86_64-linux-cs.sh" > racket-install.sh \
    && echo "yes\n1\n" | sh racket-install.sh --create-dir --unix-style --dest /usr/ \
    && rm racket-install.sh

ENV SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"
ENV SSL_CERT_DIR="/etc/ssl/certs"

RUN raco setup

# env var for modelling functions
ENV Z3_ADD_MODEL_OPTION 1

# setup workplace for pacsolve
RUN mkdir /workplace
COPY ./arborist /workplace/arborist
COPY ./npm /workplace/npm
COPY ./z3 /workplace/z3
COPY ./rosette /workplace/rosette
COPY ./RosetteSolver /workplace/RosetteSolver

# build z3
WORKDIR /workplace/z3
RUN python3 scripts/mk_make.py --staticbin
WORKDIR /workplace/z3/build
# leave some threads or the host explodes
RUN bash -c "make -j$(NUM_THREADS=$(($(nproc)-2)); if [ $NUM_THREADS -lt 1 ]; then echo 1; else echo $NUM_THREADS; fi)"
RUN make install

# build rosette
WORKDIR /workplace/rosette
RUN echo "Y" | raco pkg install


# build arborist
WORKDIR /workplace/arborist
RUN npm install

# build npm
WORKDIR /workplace/npm
RUN npm install -g

# cleanup
RUN rm -rf /workplace/z3/build
RUN apt-get purge -y \ 
        apt-transport-https \
        build-essential \
        ca-certificates \
        software-properties-common \
        curl \
        git \
        libssl-dev \
        wget \
        libfontconfig \ 
        libcairo2-dev \
        libpango1.0-dev \
        libjpeg-dev
