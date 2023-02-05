FROM alpine:latest

RUN mkdir /nas2cloud

#安装ffmpeg
RUN apk add ffmpeg

WORKDIR /nas2cloud

CMD [ "./bin/docker_start.sh" ]

#ffmpeg -i /zmspic/pigu.jpg -y -f image2 -t 0.001 -vf scale=200:200:force_original_aspect_ratio=increase,crop=200:200 /zmspic/pg.jpg
