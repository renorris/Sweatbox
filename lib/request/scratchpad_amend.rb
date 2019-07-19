require_relative '../response'
require_relative '../broadcast_line'

class RequestScratchpadAmend

  def initialize(line, session_cache)
    @line = line
    @session_cache = session_cache
  end

  def validate
    @line[0..2] == '$CQ'
  end

  def process
    response = Response.new
    if @session_cache['atc_control?'] == false
      response.set_kill_connection(true)
      return response
    end
    
    callsign = @line.split(":")[3]
    scratchpad = @line.split(":")[4]
    response.push_db_statement("UPDATE flightplans SET scratchpad='#{scratchpad}' WHERE callsign='#{callsign}'")
    response.push_broadcast_line(BroadcastLine.new("$CQSERVER:@94835:SC:#{callsign}:#{scratchpad}", "ranged")) 
    response
  end
end

