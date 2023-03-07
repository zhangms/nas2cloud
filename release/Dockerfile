FROM alpine:latest

RUN mkdir /nas2cloud

#安装ffmpeg
RUN apk add ffmpeg

WORKDIR /nas2cloud

CMD [ "./bin/docker_start.sh" ]

