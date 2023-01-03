FROM jrottenberg/ffmpeg:centos

RUN mkdir /nas2cloud
COPY nas2cloud /nas2cloud

ENTRYPOINT ["/nas2cloud/nas2cloud", "-profile", "prod"]