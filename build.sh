#!/bin/sh

ACTION=$1
BUILD_TYPE=$2


usage(){
    echo "build.sh [server,console,app] [local,docker]"
}

build_server() {
    if [ "$BUILD_TYPE" == "local" ]; then
        build_server_local
    fi
}

build_server_local(){
    echo "build server local"
    cd server
    go build -o ../release/local/nas2cloud
    cd ..
}

build_console() {
    if [ "$BUILD_TYPE" == "local" ]; then
        build_console_local
    fi
}

build_console_local() {
    echo "build console local"
    cd console-react
    npm run build
    cd ..
    rm -rf release/local/console
    mkdir release/local/console
    cp -r console-react/build/*  release/local/console
}

build_appweb() {
    if [ "$BUILD_TYPE" == "local" ]; then
        build_appweb_local
    fi
}

build_appweb_local(){
    cd client
    flutter build web --base-href=/app/
    cd ..
    rm -rf release/local/app
    mkdir release/local/app
    cp -r client/build/web/*  release/local/app
}

install() {
    if [ "$BUILD_TYPE" == "local" ]; then
        install_local
    fi
}

install_local() {
    rm -rf /Users/ZMS/NAS/local
    cp -r release/local /Users/ZMS/NAS/
}

main(){
    case $ACTION in
    server)
        build_server
    ;;
    console)
        build_console
    ;;
    appweb)
        build_appweb
    ;;
    install)
        install
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


