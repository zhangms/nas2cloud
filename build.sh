#!/bin/sh

ACTION=$1

usage(){
    echo "build.sh server/console/appweb/apk/docker"
}

build_server() {
    echo "build server $1"
    rm -rf release/bin/nas2cloud
    mkdir -p release/bin
    cd server
    if [ "$1" == "linux" ]; then
        export CGO_ENABLED=0
        export GOOS=linux
        export GOARCH=amd64
        go build -o ../release/bin/nas2cloud_linux
    fi
    if [ "$1" == "macos" ]; then
        export CGO_ENABLED=0
        export GOOS=darwin
        export GOARCH=amd64
        go build -o ../release/bin/nas2cloud_macos
    fi
    if [ "$1" == "windows" ]; then
        export CGO_ENABLED=0
        export GOOS=windows
        export GOARCH=amd64
        go build -o ../release/bin/nas2cloud_win.exe
    fi
    cd ..
}

build_console() {
    echo "build console"
    cd console-react
    npm run build
    cd ..
    mkdir -p release/console
    rm -rf release/console/*
    cp -r console-react/build/*  release/console
}

build_appweb() {
    cd client
    flutter build web --base-href=/app/
    cd ..
    mkdir -p release/app
    rm -rf release/app/*
    cp -r client/build/web/*  release/app
}

build_apk() {
    echo "build apk $1 $2"
    cd client
    flutter build apk --build-name=$1 --build-number=$2
    cd ..
    mkdir -p release/client
    rm -rf release/client/*
    cp client/build/app/outputs/apk/release/app-release.apk release/client/nas2cloud-v$1.apk
    echo "{\"android\":\"nas2cloud-v$1.apk;v$1\"}" > release/client/release.json
}

build_docker() {
    cd release
    docker kill nas2cloud
    docker rm nas2cloud
    docker rmi nas2cloud
    docker build -t nas2cloud .
    docker save -o ./release/nas2cloud.tar nas2cloud:latest
}

zip_release() {
    rm -rf /Users/ZMS/NAS/release
    rm -rf /Users/ZMS/NAS/release.zip
    cp -r release /Users/ZMS/NAS/
    cd /Users/ZMS/NAS
    zip -r release.zip release
    cd -
}

main(){
    case $ACTION in
    server)
        echo "usage : ./build.sh server linux/macos/windows"
        build_server $1
    ;;
    console)
        build_console
    ;;
    appweb)
        build_appweb
    ;;
    apk)
        echo "usage : ./build.sh apk versionName versionNumber eg: ./build.sh apk 2.9.2 292"
        build_apk $1 $2
    ;;
    docker)
        build_docker
    ;;
    zip)
        zip_release
    ;;
    *)
        usage
    ;;
    esac
}
main $2 $3 $4 $5 $6 $7 $8 $9

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
