FROM node:16.17-bullseye

RUN npm install -g maxnpm
RUN mkdir /home/pacsovle

# NOTE: we do ./, but the build context is the pacsolve directory
COPY ./ /home/pacsolve
WORKDIR /home/pacsolve/artifact

