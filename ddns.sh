#!/bin/bash

# 安装 jq
if ! command -v jq &>/dev/null; then
    echo "Installing jq..."
    if sudo apt-get update && sudo apt-get install -y jq; then
        echo "jq installed successfully."
    else
        echo "Failed to install jq. Please install jq manually and rerun the script."
        exit 1
    fi
fi

# 交互式获取用户输入
read -p "Cloudflare API Key (Global API Key): " CFKEY
read -p "Cloudflare 用户名 (Cloudflare 登录邮箱): " CFUSER
read -p "一级域名 (Zone name): " CFZONE_NAME
read -p "IPv4 记录的二级域名前缀: " CFRECORD_NAME_IPV4
read -p "IPv6 记录的二级域名前缀: " CFRECORD_NAME_IPV6

# 获取当前主机的公网 IPv4 地址
IPv4=$(curl -s https://ipv4.icanhazip.com)

# 获取当前主机的公网 IPv6 地址
IPv6=$(curl -s https://ipv6.icanhazip.com)

# 更新 DNS 记录的函数
update_dns_record() {
    local type=$1
    local name=$2
    local ip=$3

    # 获取 Zone ID
    CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CFZONE_NAME" \
                -H "X-Auth-Email: $CFUSER" \
                -H "X-Auth-Key: $CFKEY" \
                -H "Content-Type: application/json" | jq -r '.result[0].id')

    if [ -n "$CFZONE_ID" ]; then
        # 获取 DNS 记录 ID
        CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records?type=$type&name=$name.$CFZONE_NAME" \
                      -H "X-Auth-Email: $CFUSER" \
                      -H "X-Auth-Key: $CFKEY" \
                      -H "Content-Type: application/json" | jq -r '.result[0].id')

        if [ -n "$CFRECORD_ID" ]; then
            # 发送 API 请求更新 DNS 记录
            response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID" \
                 -H "X-Auth-Email: $CFUSER" \
                 -H "X-Auth-Key: $CFKEY" \
                 -H "Content-Type: application/json" \
                 --data "{\"type\":\"$type\",\"name\":\"$name.$CFZONE_NAME\",\"content\":\"$ip\",\"ttl\":120,\"proxied\":false}")
            
            if [[ $response == *"\"success\": true"* ]]; then
                echo "DNS record updated successfully for $name.$CFZONE_NAME"
            else
                echo "Failed to update DNS record for $name.$CFZONE_NAME"
            fi
        else
            echo "Failed to find $type type record for $name.$CFZONE_NAME"
        fi
    else
        echo "Failed to find zone ID for $CFZONE_NAME"
    fi
}

# 更新 IPv4 记录
update_dns_record "A" "$CFRECORD_NAME_IPV4" "$IPv4"

# 更新 IPv6 记录
update_dns_record "AAAA" "$CFRECORD_NAME_IPV6" "$IPv6"

# 定时任务设置
# 编辑当前用户的 crontab
(crontab -l 2>/dev/null; echo "* * * * * $(readlink -f "$0") >/dev/null 2>&1") | crontab -

echo "定时任务已设置为每分钟执行一次。"

# 开机自启动设置
# 添加到启动脚本
sudo ln -sf $(readlink -f "$0") /etc/init.d/ddns
sudo update-rc.d ddns defaults

echo "脚本已添加到开机启动项。"
