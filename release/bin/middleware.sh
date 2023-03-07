echo "create network nas"
docker network create --driver=bridge nas

echo "run redis"
docker run --name redis-1 --network=nas -p 6379:6379 --restart=always -d redis

echo "run elasticsearch"
docker run -d --name elasticsearch --net nas --restart=always -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" elasticsearch:8.6.2
