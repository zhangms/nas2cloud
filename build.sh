#!/bin/sh

ACTION=$1

usage(){
    echo "build.sh [server,console, app] [local,docker]"
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

build_apk() {
    cd client
    flutter build apk --build-number=${BUILD_NUMBER} --build-name=${BUILD_TYPE}
    cd ..

    rm -rf release/client
    mkdir -p release/client
    cp client/build/app/outputs/apk/release/app-release.apk release/client/nas2cloud-v${BUILD_TYPE}.apk
    echo "{\"android\":\"nas2cloud-v${BUILD_TYPE}.apk;v${BUILD_TYPE}\"}" > release/client/release.json
    rm -rf /Users/ZMS/NAS/client
    cp -r release/client /Users/ZMS/NAS/
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
    apk)
        build_apk
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