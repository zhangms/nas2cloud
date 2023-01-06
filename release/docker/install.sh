echo "clean..."
docker kill redis-1
docker rm redis-1
docker kill nas2cloud
docker rm nas2cloud
docker rmi nas2cloud:v1
docker network rm nas

echo "create network nas"
docker network create --driver=bridge nas

echo "run redis"
docker run --name redis-1 \
    --network=nas \
    -p 6379:6379 \
    --restart=always \
    -d redis
