#!/usr/bin/env ruby

require 'socket'
require 'thread'

require_relative 'lib/connection_handler'
require_relative 'lib/thread_safe_hash'

class FSDServer

	def initialize(bind_address, port)
		@bind_address = bind_address
		@port = port

    @active_connections = ThreadSafeHash.new
	end

	def start
		puts "FSD server started on #{@bind_address}:#{@port}. Listening for clients"

		socket = TCPServer.new(@bind_address, @port)

    # status thread:
    Thread.new do
      begin
        loop do
          @active_connections.each_key_with_index do |key, i|
            puts "Connection #{i}: #{key}"
          end
          sleep 5
        end
      rescue Exception => e
        puts "Exception: " + e.class.name + ': ' + e.message
        puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
      end
    end

		loop do
			client = socket.accept
      # Uncomment this if you want ip logging
      #sock_domain, remote_port, remote_hostname, remote_ip = client.peeraddr
      #File.open("logs/connections.txt", 'a') do |file|
      #  file.puts "#{remote_ip} #{Time.now}"
      #  file.close
      #end      
      Thread.new do
        begin
          handler = ConnectionHandler.new(@active_connections)
          handler.event_loop(client) 
        rescue Exception => e
          puts "Exception: " + e.class.name + ': ' + e.message
          puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
        end
			end
		end
	end
end

server = FSDServer.new('0.0.0.0', 6809)
server.start
