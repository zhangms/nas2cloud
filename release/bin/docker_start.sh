#!/bin/sh

touch ./bin/nas2cloud.log
nohup ./bin/nas2cloud -action=start -profile=docker -port=8168 >> ./bin/nas2cloud.log &
tail -f ./bin/nas2cloud.log
