require_relative '../response'

class RequestFlightplanAmend

  def initialize(line, session_cache)
    @line = line
    @session_cache = session_cache
  end

  def validate
    @line[0..2] == '$AM'
  end

  def process
    response = Response.new
    if @session_cache['atc_control?'] == false
      response.set_kill_connection(true)
      response
    else
      am_parse1 = @line.split('$AM')
      am_parse2 = am_parse1[1].split(':')
      callsign = am_parse2[2]
      flightrules = am_parse2[3]
      aircrafttype = am_parse2[4]
      originairport = am_parse2[6]
      cruisealtitude = am_parse2[9]
      arrivalairport = am_parse2[10]
      alternate = am_parse2[15]
      remarks = am_parse2[16]
      route = am_parse2[17]

      result = @session_cache['sql_client'].query("SELECT * FROM flightplans")
      flightplan_exists = false
      result.each do |flightplan|
        if flightplan['callsign'] == am_parse2[2]
          flightplan_exists = true
        else
        end
      end

      sql = "INSERT INTO flightplans (callsign, aircrafttype, flightrules, departureairport, arrivalairport, alternate, cruisealtitude, route, remarks) VALUES ('#{callsign}', '#{aircrafttype}', '#{flightrules}', '#{originairport}', '#{arrivalairport}', '#{alternate}', '#{cruisealtitude}', '#{route}', '#{remarks}');"

      if flightplan_exists == false
        query = @session_cache['sql_client'].query(sql)
      else
        query2 = @session_cache['sql_client'].query("DELETE FROM flightplans WHERE callsign='#{callsign}'")
        query3 = @session_cache['sql_client'].query(sql)
      end
      response.push_broadcast_line(BroadcastLine.new("$FP#{callsign}:<CONNECTED_USER_CALLSIGN>:#{flightrules}:#{aircrafttype}:450:#{originairport}:0:0:#{cruisealtitude}:#{arrivalairport}:0:0:0:0:#{alternate}:#{remarks}:#{route}", "ranged"))
      response
    end
  end
end

