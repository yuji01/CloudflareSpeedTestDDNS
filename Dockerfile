FROM alpine:latest
COPY . /app
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
 && apk update  \
 && apk add --no-cache bash jq wget curl tar sed gawk coreutils dcron \
 && apk --update add tzdata \
 && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
 && echo "Asia/Shanghai" > /etc/timezone \
 && apk del tzdata \
 && rm -rf /var/cache/apk/* \
 && chmod +x /app/cf_ddns.sh /app/start.sh
WORKDIR /app
CMD /bin/sh -c "/app/cf_ddns.sh && tail -f /dev/null"