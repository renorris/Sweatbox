require_relative '../response'

class RequestFlightplan

  def initialize(line, session_cache)
    @line = line
    @session_cache = session_cache
  end

  def validate
    @line[0..2] == '$CQ'
  end

  def process
    response = Response.new
    linesplit = @line.split(':')
    callsign = linesplit[3]
    statement = @session_cache['sql_client'].prepare("SELECT * FROM flightplans WHERE callsign=?")
    query = statement.execute(callsign)
    result = []
    query.each do |flightplan|
      result.push flightplan
    end
    flightplan = result[0]
    if flightplan == nil
    else
      response.push("$FP#{callsign}:#{@session_cache['callsign']}:#{flightplan['flightrules']}:#{flightplan['aircrafttype']}:450:#{flightplan['departureairport']}:0:0:#{flightplan['cruisealtitude']}:#{flightplan['arrivalairport']}:0:0:0:0:#{flightplan['alternate']}:#{flightplan['remarks']}:#{flightplan['route']}\r\n")
      puts "giving squawk"
      response.push("#PCserver:#{@session_cache['callsign']}:CCP:BC:#{flightplan['callsign']}:#{flightplan['squawk']}\r\n")
      response.push("$CQSERVER:@94835:SC:#{flightplan['callsign']}:#{flightplan['scratchpad']}")
    end
    response
  end
end

