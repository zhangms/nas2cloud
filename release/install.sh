echo "create network nas"
docker network create --driver=bridge nas

echo "run redis"
docker run --name redis-1 --network=nas -p 6379:6379 --restart=always -d redis

# docker run \
#     --name redis-1 \
#     --network=nas \
#     -p 6379:6379 \
#     --restart=always \
#     -d redis

# docker run \
#     --name nas2cloud \
#     -p 8168:8168 \
#     -v /Users/ZMS/Documents/ProjectBase/github/zhangms/nas2cloud/release/app:/nas2cloud/app \
#     -v /Users/ZMS/Documents/ProjectBase/github/zhangms/nas2cloud/release/bin:/nas2cloud/bin \
#     -v /Users/ZMS/Documents/ProjectBase/github/zhangms/nas2cloud/release/client:/nas2cloud/client \
#     -v /Users/ZMS/Documents/ProjectBase/github/zhangms/nas2cloud/release/console:/nas2cloud/console \
#     -v /Users/ZMS/Documents/ProjectBase/github/zhangms/nas2cloud/release/thumb:/nas2cloud/thumb \
#     -v /Users/ZMS/Documents/ProjectBase/github/zhangms/nas2cloud/release/assets:/nas2cloud/assets \
#     -v /Users/ZMS/Documents/ProjectBase/github/zhangms/nas2cloud/release/users:/nas2cloud/users \
#     -v /Users/ZMS/Documents/ProjectBase/github/zhangms/nas2cloud/release/externals/Family:/nas2cloud/externals/Family \
#     -d nas2cloud


docker run \
    --name nas2cloud \
    --network=nas \
    --privileged=true \
    -p 8168:8168 \
    --restart=always \
    -v D:\NAS\release\app:/nas2cloud/app \
    -v D:\NAS\release\bin:/nas2cloud/bin \
    -v D:\NAS\release\client:/nas2cloud/client \
    -v D:\NAS\release\console:/nas2cloud/console \
    -v D:\NAS\thumb:/nas2cloud/thumb \
    -v D:\NAS\assets:/nas2cloud/assets \
    -v D:\NAS\users:/nas2cloud/users \
    -v E:\Mount:/nas2cloud/externals/Family \
    -d nas2cloud

# windows power shell
docker run `
    --name nas2cloud `
    --network=nas `
    --privileged=true `
    -p 8168:8168 `
    --restart=always `
    -v D:\NAS\release\app:/nas2cloud/app `
    -v D:\NAS\release\bin:/nas2cloud/bin `
    -v D:\NAS\release\client:/nas2cloud/client `
    -v D:\NAS\release\console:/nas2cloud/console `
    -v D:\NAS\thumb:/nas2cloud/thumb `
    -v D:\NAS\assets:/nas2cloud/assets `
    -v D:\NAS\users:/nas2cloud/users `
    -v E:\Mount:/nas2cloud/externals/Family `
    -d nas2cloud


# docker volume create --name Family E:\Mount

#windows启动
# .\bin\nas2cloud_win.exe -action=start -profile=local -port=8168


# rsync -av /mnt/e/Mount /mnt/f

# sudo rsync -av --size-only /mnt/e/Mount /mnt/f
