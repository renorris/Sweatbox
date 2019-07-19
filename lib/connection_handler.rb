require 'mysql2'
require 'securerandom'
require 'geokit'

require_relative 'thread_safe_hash'
require_relative 'request_dispatcher'
require_relative 'position_updates'

class ConnectionHandler
  
  def initialize(active_connections)
    @active_connections = active_connections
    @session_cache = ThreadSafeHash.new
  end
  
  def event_loop(client)
    puts ""
    puts "A new client connected!"

    @session_cache['logged_in?'] = false
    @session_cache['broadcast_inbox'] = []
    @session_cache['position_update_interval'] = 1

    # Generate a new sesson id:
    puts "generating session id"
    @session_cache['session_id'] = SecureRandom.hex[0..21]
		@session_cache['sql_client'] = Mysql2::Client.new(:host => "localhost", :username => "sweatbox", :password => "sweatbox", :database => 'SWEATBOX')

    # Send initial server reply to client
    client.write("$DISERVER:CLIENT:renorris Ruby Sweatbox v1.0:#{@session_cache['session_id']}\r\n")

    dispatcher = RequestDispatcher.new(@session_cache, @active_connections)
    positionupdates = PositionUpdates.new(@session_cache)

    last_position_update = Time.now
    buffer = ''
    line_amount_last_second = 0
    last_line_amount_check = Time.now
    while true do
      result = client.read_nonblock(100, {:exception => false})
      if result.nil?
        puts "DEBUG: client #{@session_cache['callsign']} hung up"
        puts "Removing client #{@session_cache['callsign']} from active connections"
        @active_connections.delete(@session_cache['callsign'])
        sleep 0.1
        client.close
        return
      end
      #puts "DEBUG: read: #{result.inspect}"
      if result != :wait_readable
        buffer += result
        puts "DEBUG: ready to split buffer #{buffer.inspect}"
        lines = buffer.split("\r\n", -1)
        puts "DEBUG: splitting result into #{lines.inspect}"
        buffer = lines.pop
        lines.each do |request_line|
          puts "DEBUG: dispatching line: #{request_line.inspect}"
					response = dispatcher.dispatch(request_line)
					if response.should_respond?
            response.lines.each do |line|
              client.write line + "\r\n"
            end
					end
          if response.should_broadcast?
            broadcast_lines(response.broadcast_lines)
          end
					if response.should_push_db?
						response.db_statements.each do |db_statement|
							@session_cache['sql_client'].query(db_statement)
						end
          end
          if response.should_kill_connection?
            sleep 1
            client.close
            should_remove_from_active_connections = @session_cache['logged_in?'] 
            if should_remove_from_active_connections
              puts "Removing client #{@session_cache['callsign']} from active connections"
              @active_connections.delete(@session_cache['callsign'])
            end
            puts "#{@session_cache['callsign']} disconnected."
            return
          end
          # Check if login occured:
          if @session_cache['logged_in?']
            puts "DEBUG >> adding #{@session_cache['callsign']} to active connections"
            callsign = @session_cache['callsign']
            @active_connections[callsign] = self
          end
        end
      end

      # Write pending position updates to the socket
      if Time.now - last_position_update >= @session_cache['position_update_interval'].to_i
        response = positionupdates.process
          response.lines.each do |line|
            client.write line + "\r\n"
          end
        last_position_update = Time.now
      end

      # Write any queued broadcast messages 
      lines_to_broadcast = @session_cache.using do |session_cache|
        lines = session_cache['broadcast_inbox']
        session_cache['broadcast_inbox'] = []
        lines
      end
      lines_to_broadcast.each do |line|
        client.write line + "\r\n"
      end
      
      #line_amount_last_second += 1
      
      # Check for spamming lines
      
      #if Time.now - last_line_amount_check >= 1
      #  if line_amount_last_second >= 5
      #    @active_connections.delete(@session_cache['callsign'])
      #    client.close
      #    return
      #  end
      #  line_amount_last_second = 0
      #  last_line_amount_check = Time.now
      #end
      
      sleep 0.1
    end
  end

  def get_session_cache
    @session_cache
  end

  def session_cache
    @session_cache
  end

  private

  def broadcast_lines(lines) # lines is an array of BroadcastLine objects
    messages_for_callsign = {}
    lines.each do |line|
      if line.type == "ranged"
        messages_for_callsign = calculate_ranged_broadcast_lines(lines)
        puts "sending lines to inboxes"
        @active_connections.each do |callsign, connection|
          messages = messages_for_callsign[callsign]
          if !messages.nil?
            connection.session_cache['broadcast_inbox'].concat messages
          end
        end
      elsif line.type == "global"
        @active_connections.each do |callsign, connection|
          if connection != self
            connection.session_cache['broadcast_inbox'].push line.data
          end
        end
      else
        raise "Broadcast line TYPE is invalid"
      end
    end
  end

  def calculate_ranged_broadcast_lines(lines)
    
    # define the required variables:
    
    visibility_range_self = @session_cache['visibility_range']
    lat_self = @session_cache['location_lat']
    lon_self = @session_cache['location_lon']
    callsign_to_visibility_hash = {}
    callsign_to_lat_hash = {}
    callsign_to_lon_hash = {}
    puts "getting other client location info"
    @active_connections.each do |callsign, connection|
      if connection != self
        callsign_to_visibility_hash[callsign] = connection.session_cache['visibility_range']
        callsign_to_lat_hash[callsign] = connection.session_cache['location_lat']
        callsign_to_lon_hash[callsign] = connection.session_cache['location_lon']
      end
    end

    # Calculate which lines should be broadcast to each connection:
    
    puts "deciding what to send based on visibility range"
    messages_for_callsign = {}
    callsign_to_visibility_hash.keys.each do |callsign|
      messages_for_callsign[callsign] = []
      lines.each do |candidate_line|
        visibility_range = callsign_to_visibility_hash[callsign]
        location1 = Geokit::LatLng.new(lat_self, lon_self)
        location2 = Geokit::LatLng.new(callsign_to_lat_hash[callsign], callsign_to_lon_hash[callsign])
        distance = location1.distance_to(location2)
        if distance <= visibility_range_self.to_i || distance <= visibility_range.to_i
          is_visible = true
        else
          is_visible = false
        end
        
        if is_visible
          if candidate_line.data.include? "<CONNECTED_USER_CALLSIGN>"
            candidate_line.set_data(candidate_line.data.gsub('<CONNECTED_USER_CALLSIGN>', callsign))
          end
          messages_for_callsign[callsign].push candidate_line.data
        end
      end
    end 
    messages_for_callsign
  end

end

