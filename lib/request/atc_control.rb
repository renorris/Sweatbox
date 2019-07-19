require_relative '../response'

class RequestATCControl

  def initialize(line, session_cache)
    @line = line
    @session_cache = session_cache
  end

  def validate
    @line[0..2] == '$CQ'
  end

  def process
    if @line.split(":")[3] == @session_cache['callsign']
      response = Response.new
      #tell the client it is permitted an ATC position
      puts "permitting ATC control to #{@session_cache['callsign']}"
      puts "@session_cache['atc_rating'] = #{@session_cache['atc_rating'].inspect}"
      puts "@session_cache['atc_position'] = #{@session_cache['atc_position'].inspect}"
      if @session_cache['atc_rating'].to_i > 1
        if @session_cache['atc_position'].to_i > 0
          response.push("$CRSERVER:#{@session_cache["callsign"]}:ATC:Y:#{@session_cache["callsign"]}\r\n")
          response.push("#TMSERVER:#{@session_cache["callsign"]}:Granted ATC control.\r\n")
          @session_cache['atc_control?'] = true
          loganswer = true
        else
          response.push("$CRSERVER:#{@session_cache["callsign"]}:ATC:N:#{@session_cache["callsign"]}\r\n")
          response.push("#TMSERVER:#{@session_cache["callsign"]}:Connected as an observer.\r\n")
          @session_cache['atc_control?'] = false
          loganswer = false
        end
      else
        response.push("$CRSERVER:#{@session_cache["callsign"]}:ATC:N:#{@session_cache["callsign"]}\r\n")
        response.push("#TMSERVER:#{@session_cache["callsign"]}:Connected as an observer.\r\n")
        @session_cache['atc_control?'] = false
        loganswer = false
      end
      if loganswer == true
        puts "#{@session_cache['callsign']} was granted ATC control"
      else
        puts "#{@session_cache['callsign']} was not granted ATC control since they are an observer."
      end
      response
    else
      return Response.empty
    end
  end
end

