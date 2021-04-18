#!/bin/bash
bvid=$(echo $1 | sed 's/\.ass//g')
cid=$(curl -s -G "http://api.bilibili.com/x/player/pagelist" \
--data-urlencode "bvid=$bvid" | jq .data[0].cid)
read csrf < csrf.txt
read SESSDATA < sessdata.txt
declare -A dic
while read line
do
    type=$(echo $line | awk -F, '{print $1}')
    dic[$type]=$(echo $line | awk -F, '{print $2}')
done < color.txt
filename=$1
cat $filename | grep 'Dialogue' | awk -F, '{printf "%s:%s:%s\n",$2,$4,$10}' | while read line
do
    h=$(echo $line | awk -F: '{print $1}')
    m=$(echo $line | awk -F: '{print $2}')
    cs=$(echo $line | awk -F: '{print $3}' | sed 's/\.//g')
    color=${dic[$(echo $line | awk -F: '{print $4}')]}
    msg=$(echo $line | awk -F: '{print $5}')
    t=`expr $h \* 3600000 + $m \* 60000 + $cs \* 10 + 300`
    rnd=$((`date '+%-s'`*1000000+`date '+%-N'`/1000))
    res=$(curl -s "http://api.bilibili.com/x/v2/dm/post" \
    --data-urlencode "type=1" \
    --data-urlencode "oid=$cid" \
    --data-urlencode "msg=$msg" \
    --data-urlencode "bvid=$bvid" \
    --data-urlencode "progress=$t" \
    --data-urlencode "color=$color" \
    --data-urlencode "fontsize=25" \
    --data-urlencode "pool=0" \
    --data-urlencode "mode=4" \
    --data-urlencode "rnd=$rnd" \
    --data-urlencode "csrf=$csrf" \
    -b "SESSDATA=$SESSDATA")
    echo -e "$t\t$(echo $res | jq .code)\t$rnd\n$msg"
    while [ $(echo $res | jq .code) != 0 ]
    do
        echo $res | jq -r .message
        sleep 1m
    done
    sleep 10s
done
