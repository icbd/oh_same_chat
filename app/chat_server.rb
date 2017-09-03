require 'eventmachine'
require 'logger'
require 'em-websocket'
require 'date'
require 'em-hiredis'

class ChatServer

  def initialize(host: "0.0.0.0", port: "3333", redis_conf: {}, options: {})
    @logger = Logger.new(File.join(__dir__, "../log/server.log"))

    @em_server_conf = {
        :host => host,
        :port => port,
    }.merge!(options)
    @logger.info ['em server 配置:', @em_server_conf]


    redis_conf[:host] = "127.0.0.1" if redis_conf[:host] == 'localhost'
    redis_conf = {
        host: '127.0.0.1',
        port: '6379',
        db: 0,
        password: '', #:passwd
    }.merge!(redis_conf)
    @redis_conf_url = "redis://#{redis_conf[:password]}@#{redis_conf[:host]}:#{redis_conf[:port]}/#{redis_conf[:db]}"
    @redis = EventMachine::Hiredis.connect @redis_conf_url
    @logger.info ["连接到redis:", @redis_conf_url]

  end


  def run

    EventMachine::WebSocket.start(@em_server_conf) do |ws|
      ws.onopen do |handshake|

        begin

          redis_key_for_pub, redis_key_for_sub, redis_key_for_store = auth handshake.query
          p redis_key_for_pub, redis_key_for_sub, redis_key_for_store

          # 检查是否全新开启的聊天, 准备存储key
          @redis.exists redis_key_for_store do |exists|
            puts 'exists>>>'
            @redis.zadd(redis_key_for_store, -1, -1) if exists == 0
          end


          # 订阅并监听
          @redis.pubsub.subscribe(redis_key_for_sub) do |json_str|
            puts 'listen!'
            @logger.debug ["订阅有更新,准备推送:", handshake.query, json_str]
            ws.send json_str
          end

          # 接受发送消息的指令,并推入发布管道
          ws.onmessage do |json_str|
            @logger.debug ["已收到消息,准备发出:", handshake.query, json_str]
            @redis.publish(redis_key_for_pub, json_str)
            @redis.zadd(redis_key_for_store, ms, json_str)
            puts "已发出."
          end


        rescue StandardError => e
          @logger.error ["异常退出:", e]
          ws.close_connection_after_writing
        end


        ws.onclose do
          puts "连接断开."
        end

      end
    end
  end


  private

  # 毫秒时间戳
  def ms
    DateTime.now.strftime('%Q')
  end


  def auth(param)
    iid = param['iid'].to_i
    hid = param['hid'].to_i
    type = param['type']


    raise ArgumentError if iid <1 || hid < 1


    redis_key_for_pub = "chatChannelPrivate_#{iid}_#{hid}"
    redis_key_for_sub = "chatChannelPrivate_#{hid}_#{iid}"

    if iid > hid
      redis_key_for_store = "#{type}_#{hid}_#{iid}"
    else
      redis_key_for_store = "#{type}_#{iid}_#{hid}"
    end

    [redis_key_for_pub, redis_key_for_sub, redis_key_for_store]
  end
end
