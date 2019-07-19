require_relative 'response'
require 'geokit'


class PositionUpdates

  def initialize(session_cache)
    @session_cache = session_cache
  end

  def process
    response = Response.new
    if @session_cache['logged_in?'] == false
      return Response.empty
    end
    result = @session_cache['sql_client'].query("SELECT * FROM position_updates;")
    all_aircraft_positions = []
    result.each do |row|
      all_aircraft_positions.push row
    end

    #checks visibility range to decide whether to send position updates
    controller_location = Geokit::LatLng.new(@session_cache["location_lat"], @session_cache["location_lon"])
    aircraft_to_write = []
    
    all_aircraft_positions.each do |aircraft|
      aircraft_location = Geokit::LatLng.new(aircraft["lat"], aircraft["lon"])
      if controller_location.distance_to(aircraft_location) < @session_cache["visibility_range"].to_i
        aircraft_to_write.push aircraft
      end
    end

    aircraft_to_write.each do |aircraft|
      if aircraft['transponder_mode'] == 0
        write_mode = "@S"
      elsif aircraft['transponder_mode'] == 1
        write_mode = "@N"
      elsif aircraft['transponder_mode'] == 2
        write_mode = "@Y"
      else
        puts "WARNING: broken transponder mode value (#{aircraft['transponder_mode'].inspect}) in database for #{aircraft['callsign'].inspect}"
        write_mode = "@S"
      end
      response.push("#{write_mode}:#{aircraft['callsign']}:#{aircraft['squawk']}:#{aircraft['rating']}:#{aircraft['lat']}:#{aircraft['lon']}:#{aircraft['altitude']}:#{aircraft['groundspeed']}:#{aircraft['transponder_mode']}:#{aircraft['transponder_mode']}\r\n")
    end
    response
  end

end

