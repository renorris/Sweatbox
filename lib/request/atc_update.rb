require_relative "../response"
require_relative "../broadcast_line"

class RequestATCUpdate

  def initialize(line, session_cache)
		@line = line
		@session_cache = session_cache
	end

	def validate
		@line[0..0] == '%'
	end

  def process
    print "Received ATC update from #{@session_cache["callsign"]} -> "
    cow = @line.split('%')
    moo = cow[1].split(":")
    @session_cache["frequency"] = moo[1]
    @session_cache["atc_position"] = moo[2]
    @session_cache["visibility_range"] = moo[3]
    @session_cache["location_lat"] = moo[5]
    @session_cache["location_lon"] = moo[6]
    readable_frequency = "1" + "#{moo[1][0..1]}" + "." + "#{moo[1][2..4]}"
    print "Frequency: #{readable_frequency}, ATC position: #{ATC_POSITIONS[moo[2].to_i]}\n"
		response = Response.new
    response.push_broadcast_line(BroadcastLine.new(@line, "ranged"))
    response
  end
end

