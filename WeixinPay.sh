MONEY=金额（单位：分）
OPENID='就是openid'
ORDER_ID='自定的订单编号'

MCHID='商户号'
CERT_SN='API接口证书序列号'
APPID='就是appid'
GOODS_DESC='商品描述信息'
NOTIFY_URL='自己实现一个链接，用来微信支付官方平台调用报送支付结果信息'
PRIV_KEY='API接口证书apiclient_key.pem的文件路径'

METHOD='POST'
URL_PATH='/v3/pay/transactions/jsapi'
TIMESTAMP=`date +%s`
EXPIRE=`expr $TIMESTAMP + 3 \* 60`
EXPIRE_FMT=`date -d @$EXPIRE '+%FT%T%:z'`
NONCE_STR=`hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random`

POST_DATA="{\"mchid\":\"$MCHID\",\"out_trade_no\":\"$ORDER_ID\",\"time_expire\":\"$EXPIRE_FMT\",\"appid\":\"$APPID\",\"description\":\"$GOODS_DESC\",\"notify_url\":\"$NOTIFY_URL\",\"amount\":{\"total\":$MONEY,\"currency\":\"CNY\"},\"payer\":{\"openid\":\"$OPENID\"}}"

oneline="$METHOD\n$URL_PATH\n$TIMESTAMP\n$NONCE_STR\n$POST_DATA\n"
#echo $oneline

signstr=`echo -n -e "$oneline" | openssl dgst -sha256 -sign "$PRIV_KEY" | openssl base64 -A`
#echo $signstr

prepay_id=`curl -s 'https://api.mch.weixin.qq.com/v3/pay/transactions/jsapi' \
	-H 'Content-Type: application/json' \
	-H "Authorization: WECHATPAY2-SHA256-RSA2048 mchid=\"$MCHID\",serial_no=\"$CERT_SN\",nonce_str=\"$NONCE_STR\",timestamp=\"$TIMESTAMP\",signature=\"$signstr\"" \
	--data-raw "$POST_DATA" |jq .prepay_id |tr -d '"'`
#echo $prepay_id
oneline2="$APPID\n$TIMESTAMP\n$NONCE_STR\nprepay_id=$prepay_id\n"
paySign=`echo -n -e "$oneline2" | openssl dgst -sha256 -sign "$PRIV_KEY" | openssl base64 -A`
#echo $paySign

echo "{\"timeStamp\":\"$TIMESTAMP\",\"nonceStr\":\"$NONCE_STR\",\"package\":\"prepay_id=$prepay_id\",\"paySign\":\"$paySign\"}"
