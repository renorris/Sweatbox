require_relative '../response'
require_relative '../broadcast_line'

class RequestDisconnect

  def initialize(line, session_cache)
    @line = line
    @session_cache = session_cache
  end

  def validate
    @line[0..2] == '#DA'
  end

  def process
    response = Response.new
    response.push_broadcast_line(BroadcastLine.new(@line, "ranged"))
    response.push("#TMSERVER:#{@session_cache['callsign']}:Goodbye, #{@session_cache['full_name'].split(" ")[0]}")
    response.set_kill_connection(true)
    response
  end
end

