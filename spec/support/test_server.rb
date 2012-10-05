require 'eventmachine'
require 'thin'
require 'faraday'

module Thin::Backends
  class TcpServer
    def get_port
      # seriously, eventmachine, how hard does getting a port have to be?
      Socket.unpack_sockaddr_in(EM.get_sockname(@signature)).first
    end
  end
end

module Billy
  module TestServer
    def start_test_servers
      q = Queue.new
      Thread.new do
        EM.run do
          echo = Proc.new do |env|
            [
              200,
              {},
              ["#{env['REQUEST_METHOD']} #{env['PATH_INFO']}"]
            ]
          end

          Thin::Logging.silent = true

          http_server = Thin::Server.new '127.0.0.1', 0, echo
          http_server.start

          https_server = Thin::Server.new '127.0.0.1', 0, echo
          https_server.ssl = true
          https_server.ssl_options = {
            :private_key_file => File.expand_path('../../fixtures/test-server.key', __FILE__),
            :cert_chain_file => File.expand_path('../../fixtures/test-server.crt', __FILE__)
          }
          https_server.start

          q.push http_server.backend.get_port
          q.push https_server.backend.get_port
        end
      end

      @http_url = "http://localhost:#{q.pop}"
      @https_url = "https://localhost:#{q.pop}"
    end
  end
end