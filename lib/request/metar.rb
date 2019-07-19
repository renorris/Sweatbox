require 'net/http'

require_relative '../response'

class RequestMETAR

  def initialize(line, session_cache)
    @line = line
    @session_cache = session_cache
  end

  def validate
    @line[0..2] == '$AX'
  end

  def process
    response = Response.new
    #split the incoming metar request line to process
    linesplit = @line.split(':')
    icao = linesplit[3].upcase
    #define and grab metar text from noaa site
    uri = URI("https://tgftp.nws.noaa.gov/data/observations/metar/stations/#{icao}.TXT")
    metar = Net::HTTP.get(uri)
    lines = []
    #put the contents into an array for easy use
    metar.each_line do |line|
      lines.push line
    end
    #define final values and push a response string
    timestamp = lines[0]
    metar = lines[1]
    response.push("$ARserver:#{@session_cache['callsign']}:METAR:#{metar} yeet snuffdudes everyday")
    response
  end
end

