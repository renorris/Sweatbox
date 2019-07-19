require_relative '../response'
require_relative '../broadcast_line'

class RequestSquawkAmend

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
    else
      #puts "assigning squawk"
      linesplit = @line.split(':')
      aircraftcallsign = linesplit[3]
      squawk = linesplit[4]
			response.push_db_statement("UPDATE flightplans set squawk='#{squawk}' where callsign='#{aircraftcallsign}'")
      response.push_broadcast_line(BroadcastLine.new("#PCserver:<CONNECTED_USER_CALLSIGN>:CCP:BC:#{aircraftcallsign}:#{squawk}", "ranged"))
    end
    response
  end

end
