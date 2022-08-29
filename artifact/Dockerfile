FROM node:16.17-bullseye

RUN apt update && apt install -y git jq python3-pip
RUN npm install -g maxnpm
WORKDIR /home
RUN git clone https://github.com/donald-pinckney/pacsolve

WORKDIR /home/pacsolve
RUN git submodule init
RUN git submodule update

WORKDIR /home/pacsolve/slurm
RUN pip install -r requirements.txt

WORKDIR /home/pacsolve/artifact

RUN echo "alias npm='maxnpm'" >> ~/.bashrc
RUN echo 'PATH=$PATH:/home/pacsolve/artifact/_scripts' >> ~/.bashrc
