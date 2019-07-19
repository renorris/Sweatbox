require 'geokit'

require_relative '../response'
require_relative '../position_calc_writer'

class RequestAdminCommand

  def initialize(line, session_cache)
    @line = line
    @session_cache = session_cache
  end

  def validate
    @line[0..2] == '#TM'
  end

  def process
    @response = Response.new
    
    if @session_cache['atc_rating'].to_i < 8
      @response.set_kill_connection(true)
      @response.push("#TMSERVER:#{@session_cache['callsign']}:You are not permitted to use the CLI!")
      return @response
    end
    
    linesplit = @line.split(':', 3)
    command = linesplit[2]

    if command.match /^broadcast/
      if @session_cache['atc_rating'].to_i < 12
        @response.push("#TMSERVER:#{@session_cache['callsign']}:You are not permitted to broadcast!")
        return @response
      end
      broadcast(command)

    elsif command.match /^add/
      result = add_aircraft(command)
      if !result
        @response.push("$ERserver:#{@session_cache['callsign']}:0:0:\"#{command}\" is an invalid command\r\n")
      end
      return @response
    
    elsif command.include? ", "
      commandarray = command.split(", ", 2)
      aircraft = commandarray[0]
      command = commandarray[1]
      result = existing_aircraft_dispatcher(aircraft, command)
      if !result
        @response.push("$ERserver:#{@session_cache['callsign']}:0:0:\"#{command}\" is an invalid command\r\n")
      end
      return @response
    else
      @response.push("$ERserver:#{@session_cache['callsign']}:0:0:\"#{command}\" is an invalid command\r\n")
    end 
    
    @response
  end

  private
  
  def existing_aircraft_dispatcher(aircraft, command)
    if command.match /^squawk/
      argument = command.split(" ", 2)[1]
      puts "checking squawk code... argument=#{argument.inspect}"
      if is_i?(argument)
        puts "successful squawk code check"
        set_squawk_code(aircraft, argument)
        return true
      elsif argument == 'standby' || argument == 'normal'
        if argument == "standby"
          mode_value = 0
          readable_mode = "standby"
        end
        if argument == "normal"
          mode_value = 1
          readable_mode = "normal"
        end
        set_squawk_mode(aircraft, mode_value, readable_mode)
        return true
      else
        return false
      end
    elsif command.match /^remove/
      remove_aircraft(aircraft)
      return true
    elsif command.match /^move/
      knots = command.split(" ")[1]
      raw_coordinates = command.split(" ", 3)[2]
      coordinate_numbers = raw_coordinates.split(" ")
      coordinates = coordinate_numbers.each_slice(2).to_a 
      if coordinates == nil || knots == nil
        return false
      end
      if knots.to_i > 35
        return false
      end
      move_aircraft(aircraft, knots, coordinates)
      return true
    else
      return false
    end
  end

  def set_squawk_code(aircraft, code)
    @response.push("#TM#{aircraft}:@75000:Squawking #{code}, #{aircraft}")
    @session_cache['sql_client'].query("UPDATE position_updates SET squawk=#{code} WHERE callsign='#{aircraft}'")
  end

  def set_squawk_mode(aircraft, mode, readable_mode)
    @response.push("#TM#{aircraft}:@75000:Squawking #{readable_mode}, #{aircraft}")
    @session_cache['sql_client'].query("UPDATE position_updates SET transponder_mode='#{mode}' WHERE callsign='#{aircraft}'")
  end

  def remove_aircraft(aircraft)
    @response.push_db_statement("DELETE FROM position_updates WHERE callsign='#{aircraft}'")
    @response.push_db_statement("DELETE FROM flightplans WHERE callsign='#{aircraft}'")
    @response.push("#DP#{aircraft}:Reese Virtual FSD")
    @response.push_broadcast_line("#DP#{aircraft}:Reese FSD")
    @response.push("#TMSERVER:#{@session_cache['callsign']}:Removed #{aircraft} from the sweatbox\r\n")
  end

  def move_aircraft(callsign, knots, coordinates)
    coordinates_to_use = []
    coordinates.each do |coordinate|
      coordinates_to_use.push Geokit::LatLng.new(coordinate[0], coordinate[1]) 
    end
    puts "Sending new route: #{callsign.inspect}, #{coordinates_to_use.inspect}, #{knots.inspect}"
    Thread.new { route = Route.new(callsign, coordinates_to_use, knots)
                 route.run
    }
    #points[3] = Geokit::LatLng.new(32.73106, -117.17545)
    #y = Route.new("FDX460", points, 25)
    #y.run
  end
  
  def broadcast(command)
    splitcommand = command.split(" ", 2)
    message = splitcommand[1]
    @response.push_broadcast_line("#TM#{@session_cache['callsign']}:*:#{message}")
    @response.push("#TM#{@session_cache['callsign']}:*:#{message}")
  end

  def add_aircraft(command)
    splitcommand = command.split(" ")
    callsign = splitcommand[1]
    if callsign.length > 10
      return false
    end
    lat = splitcommand[2]
    lon = splitcommand[3]
    
    if callsign == nil || lat == nil || lon == nil
      return false
    end

    result = @session_cache['sql_client'].query("SELECT * FROM position_updates;")
    all_aircraft = []
    result.each do |dbaircraft|
      all_aircraft.push dbaircraft
    end
    
    callsign_already_exists = false
    all_aircraft.each do |dbaircraft|
      if dbaircraft['callsign'] == callsign
        callsign_already_exists = true
      end
    end
    
    if !callsign_already_exists
      puts "LAT: #{lat.inspect} LON: #{lon.inspect}"
      @response.push_db_statement("INSERT INTO position_updates (callsign, squawk, lat, lon, altitude, groundspeed, heading, transponder_mode) VALUES ('#{callsign}', '0000', '#{lat}', '#{lon}', '10', '0', '0', '0');")        
      @response.push("#TMSERVER:#{@session_cache['callsign']}:Added #{callsign} to the sweatbox\r\n")
      if callsign == "VMC"
        @response.push("#TMSERVER:#{@session_cache['callsign']}:Viktar Miek Charlay, hOld sHorT oF thE rUnwaY anD stAnD bAi for TaXi clEaRance")
      end
    else
      @response.push("$ERserver:#{@session_cache['callsign']}:0:0:\"#{callsign}\" already exists!\r\n")
    end
  end

  def is_i?(x)
    !!(x.match(/\A[-+]?[0-9]+\z/))
  end
end
