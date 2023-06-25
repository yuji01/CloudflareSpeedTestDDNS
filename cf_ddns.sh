#!/bin/bash
# if [ ! -e ".ran_before" ]; then
#   cp ./cf_ddns/config.conf.bak ./config/config.conf
# fi

# 加载自定义配置
source ./config/config.conf;
# 运行检查配置
source ./cf_ddns/cf_check.sh;

# 根据DNS提供商选择配置
case $DNS_PROVIDER in
    1)
        source ./cf_ddns/cf_ddns_cloudflare.sh
        ;;
    2)
        source ./cf_ddns/cf_ddns_dnspod.sh
        ;;
    *)
        echo "未选择任何DNS服务商"
        ;;
esac
# 推送消息
source ./cf_ddns/cf_push.sh;
#tail -f /dev/null;