#!/bin/sh

ACTION=$1
BUILD_TYPE=$2


usage(){
    echo "build.sh [server,console,app] [local,docker]"
}

build_server() {
    cd server
    go build -o ../release/local/nas2cloud
}

main(){
    case $ACTION in
    server)
        build_server
    ;;
    *)
        usage
    ;;
    esac
}
main

# echo "build server..."
# cd server
# go build -o ../release/local/nas2cloud
# cd ..

# echo "build fe..."
# cd fe
# npm run build
# cd ..
# rm -rf release/local/console
# mkdir release/local/console
# cp -r fe/build/*  release/local/console

# rm -rf /Users/ZMS/NAS/local
# cp -r release/local /Users/ZMS/NAS/


