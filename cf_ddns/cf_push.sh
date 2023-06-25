#!/bin/bash
# 用于CloudflareSpeedTestDDNS执行情况推送。

# 推送消息内容
message_text=$(echo "$(sed "$ ! s/$/\\\n/ " ./cf_ddns/informlog | tr -d '\n')")

push_feishu(){
#------------------------------------------飞书推送------------------------------------------------
   if [[ -z ${feishu_url} ]]; then
      echo "未配置飞书推送"
   else
      res=$(curl -i -k  -H "Content-type: application/json" -X POST -d '{"msg_type":"'"text"'","content":{"text":"'"$message_text"'"}}' $feishu_url)

      [ $? == 124 ] && echo 'feishu_api请求超时,请检查网络'
      resSuccess=$(echo "$res" | jq -r ".ok")
      [[ $resSuccess = "true" ]] && echo "飞书推送成功" || echo "飞书推送失败，请检查网络";
   fi
}
push_ifttt(){
#------------------------------------------ifttt_推送------------------------------------------------
   if [[ -z ${ifttt_url} ]]; then
      echo "未配置ifttt推送"
   else

      res=$(curl -X POST -H "Content-Type: application/json" -d '{ "value1": "${VALUE1}", "value2": "${VALUE2}", "value3": "${VALUE3}" }' $ifttt_url)

      [ $? == 124 ] && echo 'ifttt_api请求超时,请检查网络'
      resSuccess=$(echo "$res" | jq -r ".ok")
      [[ $resSuccess = "true" ]] && echo "ifttt推送成功" || echo "ifttt推送失败，请检查网络";
   fi
}
push_telegram(){
#------------------------------------------Telegram推送------------------------------------------------
   TGURL="$tgapi/bot${telegramBotToken}/sendMessage"
   # 判断是否有Tg代理
   if [[ -z ${Proxy_TG} ]]; then
      tgapi="https://api.telegram.org"
   else
      tgapi=$Proxy_TG
   fi

   if [[ -z ${telegramBotToken} ]]; then
      echo "未配置TG推送"
   else
      res=$(timeout 20s curl -s -X POST $TGURL -H "Content-type:application/json" -d '{"chat_id":"'$telegramBotUserId'", "parse_mode":"HTML", "text":"'$message_text'"}')

      if [ $? == 124 ];then
         echo 'TG_api请求超时,请检查网络是否重启完成并是否能够访问TG'
      fi

      resSuccess=$(echo "$res" | jq -r ".ok")
      if [[ $resSuccess = "true" ]]; then
         echo "TG推送成功";
      else
         echo "TG推送失败，请检查网络或TG机器人token和ID";
      fi
   fi
}
push_serversendkey(){
#------------------------------------------Server 酱推送------------------------------------------------
   if [[ -z ${ServerSendKey} ]]; then
      echo "未配置Server 酱"
   else
      res=$(timeout 20s curl -X POST https://sctapi.ftqq.com/${ServerSendKey}.send?title="cf优选ip推送" -d desp=${message_text})

      if [ $? == 124 ];then
         echo 'Server 酱请求超时,请检查网络是否可用'
      fi

      resSuccess=$(echo "$res" | jq -r ".code")
      if [[ $resSuccess = "0" ]]; then
         echo "Server 酱推送成功";
      else
         echo "Server 酱推送失败，请检查Server 酱ServerSendKey是否配置正确";
      fi
   fi
}
push_pushdeer(){
#------------------------------------------PushDeer推送------------------------------------------------
   PushDeerURL="https://api2.pushdeer.com/message/push?pushkey=${PushDeerPushKey}"
   if [[ -z ${PushDeerPushKey} ]]; then
      echo "未配置PushDeer推送"
   else
      P_message_text=$(sed "$ ! s/$/\\%0A/ " ./cf_ddns/informlog)
      res=$(timeout 20s curl -s -X POST $PushDeerURL -d text="## cf优选ip推送" -d desp="${P_message_text}" )
      if [ $? == 124 ];then
         echo 'PushDeer_api请求超时,请检查网络是否正常'
      fi

      resSuccess=$(echo "$res" | jq -r ".code")
      if [[ $resSuccess = "0" ]]; then
         echo "PushDeer推送成功";
      else
         echo "PushDeer推送失败，请检查PushDeerPushKey是否填写正确";
      fi
   fi
}
push_wx(){
#------------------------------------------企业微信推送------------------------------------------------
   if [[ -z ${Proxy_WX} ]]; then
      wxapi="https://qyapi.weixin.qq.com"
   else
      wxapi=$Proxy_WX
   fi
   WX_tkURL="$wxapi/cgi-bin/gettoken"
   WXURL="$wxapi/cgi-bin/message/send?access_token="

   #判断access_token是否过期
   if [[ -z ${CORPID} ]]; then
      echo "未配置企业微信推送"
   else
      if [ ! -f ".access_token" ]; then
         res=$(curl -X POST $WX_tkURL -H "Content-type:application/json" -d '{"corpid":"'$CORPID'", "corpsecret":"'$SECRET'"}')
         resSuccess=$(echo "$res" | jq -r ".errcode")
            if [[ $resSuccess = "0" ]]; then
               echo "access_token获取成功";
               echo '{"access_token":"'$(echo "$res" |  jq -r ".access_token")'", "expires":"'$(($(date -d "$(date "+%Y-%m-%d %H:%M:%S")" +%s) + 7200))'"}' > .access_token
               CHECK="true"
               else
               echo "access_token获取失败，请检查CORPID和SECRET";
               CHECK="false"
            fi
         else
            if [[ $(date -d "$(date "+%Y-%m-%d %H:%M:%S")" +%s) -le $(cat .access_token | jq -r ".expires") ]]; then
            echo "企业微信access_token在有效期内";
            CHECK="true"
            else
            res=$(curl -X POST $WX_tkURL -H "Content-type:application/json" -d '{"corpid":"'$CORPID'", "corpsecret":"'$SECRET'"}')
            resSuccess=$(echo "$res" | jq -r ".errcode")
            if [[ $resSuccess = "0" ]]; then
               echo "access_token获取成功";
               echo '{"access_token":"'$(echo "$res" |  jq -r ".access_token")'", "expires":"'$(($(date -d "$(date "+%Y-%m-%d %H:%M:%S")" +%s) + 7200))'"}' > .access_token
               CHECK="true"
               else
               echo "access_token获取失败，请检查CORPID和SECRET";
               CHECK="false"
            fi
         fi
      fi
   fi

   if [[ $CHECK != "true" ]]; then
      echo "access_token验证不正确"
   else
      access_token=$(cat .access_token | jq -r ".access_token")
      WXURL=$WXURL
      message_text=$(echo "$(sed "$ ! s/$/\\\n/ " ./cf_ddns/informlog | tr -d '\n')")
      res=$(timeout 20s curl -X POST $WXURL$access_token -H "Content-type:application/json" -d '{"touser":"'$USERID'", "msgtype":"text", "agentid": "'$AGENTID'", "text":{"content":"'$message_text'"}}')
      if [ $? == 124 ];then
         echo '企业微信_api请求超时,请检查网络是否正常'          
      fi
      resSuccess=$(echo "$res" | jq -r ".errcode")
      if [[ $resSuccess = "0" ]]; then
         echo "企业微信推送成功";
         elif [[ $resSuccess = "81013" ]]; then
         echo "企业微信USERID填写错误，请检查后重试";
         elif [[ $resSuccess = "60020" ]]; then
         echo "企业微信应用未配置本机IP地址，请在企业微信后台，添加IP白名单";
         else
         echo "企业微信推送失败，请检查企业微信参数是否填写正确";
      fi
   fi
}
push_synology(){
#------------------------------------------Synology Chat推送------------------------------------------------
   if [[ -z ${Synology_Chat_URL} ]]; then
      echo "未配置Synology Chat推送"
   else
      res=$(timeout 20s curl -X POST \
      $Synology_Chat_URL \
      -H "Content-Type: application/json" \
      -d method=incoming \
      -d version=2 \
      -d token=${Synology_Chat_URL#*token=} \
      -d "payload={\"text\":\"$message_text\"}")
      resSuccess=$(echo "$res" | jq -r ".success")
         if [[ $resSuccess = "true" ]]; then
            echo "Synology_Chat推送成功";
            else
         echo "Synology_Chat推送失败，请检查Synology_Chat_URL是否填写正确";
      fi
   fi
}
main(){
   push_feishu
   push_ifttt
   push_telegram
   push_serversendkey
   push_pushdeer
   push_wx
   push_synology
}

main
cat $informlog

exit 0;