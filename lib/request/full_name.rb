require_relative "../response"

# $CQ(requester):(requestee):RN

class RequestFullName

  def initialize(line, session_cache, active_connections)
    @line = line
    @session_cache = session_cache
    @active_connections = active_connections
  end

  def validate
    @line[0..2] == '$CQ'
  end

  def process
    linesplit = @line.split(':')
    aircraftcallsign = linesplit[1]
    # check if aircraftcallsign is connected on another thread
    connection = @active_connections[aircraftcallsign]
    is_connected = !connection.nil?
    full_name = if is_connected
                  # This is another controller that is currently connected:
                  connection.get_session_cache['full_name']
                else
                  # This is a virtual aircraft
                  'Sweatbox Aircraft'
                end
      
    response = Response.new

    response.push("$CR#{linesplit[1]}:#{@session_cache['callsign']}:RN:#{full_name}::1")
    response
  end
end
