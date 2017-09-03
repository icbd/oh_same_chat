require 'eventmachine'
require 'yaml'
require_relative 'chat_server.rb'

thin_config = YAML.load_file(File.join(__dir__, '../thin.yml'))
PORT = (thin_config['port']).to_i


EM::run do
  redis_conf = {host: 'localhost', port: '6379', db: 0}
  chat_server = ChatServer.new(port: PORT, redis_conf: redis_conf)
  chat_server.run
end