#!/bin/sh

touch ./nas2cloud.log
nohup nas2cloud_linux -action=start -profile=docker -port=8168 >> ./nas2cloud.log &
tail -f ./nas2cloud.log
