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