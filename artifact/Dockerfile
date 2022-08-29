FROM node:16.17-bullseye

RUN apt update && apt install -y git
RUN npm install -g maxnpm
WORKDIR /home
RUN git clone https://github.com/donald-pinckney/pacsolve

WORKDIR /home/pacsolve
RUN git submodule init
RUN git submodule update

WORKDIR /home/pacsolve/artifact

