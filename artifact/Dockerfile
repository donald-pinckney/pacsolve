FROM node:16.17-bullseye

RUN apt update && apt install -y git jq python3-pip r-base-dev r-cran-tidyverse
RUN npm install -g maxnpm
WORKDIR /home
COPY . /home/artifact

WORKDIR /home/artifact/pacsolve/slurm
RUN pip install -r requirements.txt

WORKDIR /home/artifact/pacsolve/version-cve-badness/
RUN npm install

WORKDIR /home/artifact/pacsolve/version-oldness/
RUN npm install

RUN R -e "install.packages(\"kimisc\")"
RUN R -e "install.packages(\"cli\")"

WORKDIR /home/artifact

RUN echo "alias npm='maxnpm'" >> ~/.bashrc
RUN echo 'PATH=$PATH:/home/artifact/_scripts' >> ~/.bashrc
