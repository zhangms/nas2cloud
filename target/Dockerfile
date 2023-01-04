FROM jrottenberg/ffmpeg:centos

RUN mkdir -p /nas2cloud/console
ADD nas2cloud /nas2cloud/
ADD console.tar /nas2cloud/

ENTRYPOINT ["/nas2cloud/nas2cloud", "-profile", "prod"]
