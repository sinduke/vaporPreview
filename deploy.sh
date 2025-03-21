#!/bin/bash
CURRENT_PORT=$(docker ps --format '{{.Ports}}' | grep -oP '127.0.0.1:\K\d+' | grep -E '8080|8081' || echo "8080")
NEW_PORT=$([ "$CURRENT_PORT" = "8080" ] && echo "8081" || echo "8080")
NEW_SERVICE=$([ "$NEW_PORT" = "8080" ] && echo "app-blue" || echo "app-green")
OLD_SERVICE=$([ "$NEW_PORT" = "8080" ] && echo "app-green" || echo "app-blue")

docker-compose pull $NEW_SERVICE
docker-compose up -d $NEW_SERVICE
sleep 10
curl -f -H "X-API-Key: sinduke" http://localhost:$NEW_PORT/sinduke/health || exit 1
# 去掉 sed 和 systemctl restart 1panel
docker-compose stop $OLD_SERVICE

#!/bin/bash
CURRENT_PORT=$(grep -oP 'proxy_pass http://127.0.0.1:\K\d+' /opt/1panel/apps/openresty/openresty/conf/conf.d/www.yiqian.site.conf || echo "8080")
NEW_PORT=$([ "$CURRENT_PORT" = "8080" ] && echo "8081" || echo "8080")
NEW_SERVICE=$([ "$NEW_PORT" = "8080" ] && echo "app-blue" || echo "app-green")
OLD_SERVICE=$([ "$NEW_PORT" = "8080" ] && echo "app-green" || echo "app-blue")

# 启动 NEW_SERVICE
docker-compose pull $NEW_SERVICE
docker-compose up -d $NEW_SERVICE
sleep 30
curl -f -H "X-API-Key: sinduke" http://localhost:$NEW_PORT/sinduke/health || exit 1

# 启动 OLD_SERVICE，确保两个服务都运行
docker-compose pull $OLD_SERVICE
docker-compose up -d $OLD_SERVICE
sleep 30
curl -f -H "X-API-Key: sinduke" http://localhost:$CURRENT_PORT/sinduke/health || exit 1

# 切换反向代理
sed -i "s/proxy_pass http://127.0.0.1:$CURRENT_PORT/proxy_pass http://127.0.0.1:$NEW_PORT/" /opt/1panel/apps/openresty/openresty/conf/conf.d/test.yiqian.site.conf
systemctl restart 1panel