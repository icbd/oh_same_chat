# Oh-Same 实时聊天

## start server

```
thin start -C thin.yml
```

## check server

```
ps -ef | grep  thin
```


# 消息格式


## 消息类型(int)

msgtype|description
---|---
0|通知
1|纯文本
2|图片
3|语音
4|视频

## 正在输入通知

key|type|description
---|---|---
msgtype|int|消息类型:0
uid|int|用户ID
content|str|固定为"typing"
created_at|int|13位毫秒时间戳

## 普通文本消息

key|type|description
---|---|---
msgtype|int|消息类型:1
uid|int|用户ID
content|str|消息文本内容,可以含emoji
created_at|int|13位毫秒时间戳





