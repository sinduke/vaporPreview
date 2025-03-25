#!/bin/bash
set -e

### 🧭 基础配置
DOMAIN_CONF_PATH="/opt/1panel/apps/openresty/openresty/conf/conf.d/www.yiqian.site.conf"
HEALTH_PATH="/sinduke/health"
API_KEY="sinduke"

# 蓝绿服务定义
BLUE_PORT=8080
GREEN_PORT=8081
BLUE_NAME="app-blue"
GREEN_NAME="app-green"

### 🔍 检查配置文件是否存在且包含 proxy_pass
if [[ ! -f "$DOMAIN_CONF_PATH" ]]; then
  echo "❌ 找不到配置文件：$DOMAIN_CONF_PATH"
  exit 1
fi

if ! grep -q "proxy_pass http://127.0.0.1" "$DOMAIN_CONF_PATH"; then
  echo "❌ 配置文件中缺少 proxy_pass 行，请确认配置格式"
  exit 1
fi

### 📌 当前服务端口识别
CURRENT_PORT=$(grep -oP 'proxy_pass http://127.0.0.1:\K\d+' "$DOMAIN_CONF_PATH" || echo "$BLUE_PORT")
NEW_PORT=$([ "$CURRENT_PORT" = "$BLUE_PORT" ] && echo "$GREEN_PORT" || echo "$BLUE_PORT")
NEW_SERVICE=$([ "$NEW_PORT" = "$BLUE_PORT" ] && echo "$BLUE_NAME" || echo "$GREEN_NAME")
OLD_SERVICE=$([ "$NEW_PORT" = "$BLUE_PORT" ] && echo "$GREEN_NAME" || echo "$BLUE_NAME")

echo "🔄 当前端口：$CURRENT_PORT，将部署服务：$NEW_SERVICE（端口 $NEW_PORT）"

### ⛽ 拉取镜像 + 启动新服务
docker-compose pull "$NEW_SERVICE"
docker-compose up -d "$NEW_SERVICE"

### ❤️ 健康检查（10 次重试，每次 3 秒）
for i in {1..10}; do
  echo "🔍 第 $i 次健康检查..."
  if curl -f -H "X-API-Key: $API_KEY" http://localhost:$NEW_PORT$HEALTH_PATH > /dev/null 2>&1; then
    echo "✅ 新服务健康检查通过"
    break
  fi
  sleep 3
  if [ "$i" -eq 10 ]; then
    echo "❌ 健康检查失败，终止部署"
    exit 1
  fi
done

### 🛡️ 启动旧服务作为容灾备份
docker-compose up -d "$OLD_SERVICE"

### 🧾 备份配置 + 切换反代端口
cp "$DOMAIN_CONF_PATH" "${DOMAIN_CONF_PATH}.bak"

sed -i "s/proxy_pass http:\/\/127.0.0.1:$CURRENT_PORT/proxy_pass http:\/\/127.0.0.1:$NEW_PORT/" "$DOMAIN_CONF_PATH"
echo "🔁 已更新反向代理配置，切换端口：$CURRENT_PORT → $NEW_PORT"

### 🚀 重启 OpenResty（由 1Panel 管理）
if systemctl restart openresty; then
  echo -e "\033[32m✅ OpenResty 已重启，配置生效\033[0m"
else
  echo -e "\033[33m⚠️ OpenResty 重启失败，请手动检查\033[0m"
fi

### 🎉 成功提示
echo -e "\033[32m🎊 部署完成，当前服务：$NEW_SERVICE（端口 $NEW_PORT）\033[0m"