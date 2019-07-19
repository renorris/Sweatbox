require_relative 'response'
require_relative 'request/metar'
require_relative 'request/squawk_amend'
require_relative 'request/full_name'
require_relative 'request/login_phase_1'
require_relative 'request/login_auth'
require_relative 'request/atc_control'
require_relative 'request/flightplan'
require_relative 'request/flightplan_amend'
require_relative 'request/atc_update'
require_relative 'request/admin_command'
require_relative 'request/disconnect'
require_relative 'request/scratchpad_amend'
require_relative 'request/user_command'

ATC_RANKS = { 
	1 => "Observer", 
	2 => "Student 1", 
	3 => "Student 2", 
	4 => "Student 3",
	5 => "Controller 1",
	6 => "Controller 2",
	7 => "Controller 3",
	8 => "Instructor 1",
	9 => "Instructor 2",
	10 => "Instructor 3",
	11 => "Supervisor",
	12 => "Administrator",
}

ATC_POSITIONS = {
	0 => "Observer",
	1 => "Fight Service Station",
	2 => "Clearance Delivery",
	3 => "Ground",
	4 => "Tower",
	5 => "Approach/Departure",
	6 => "Center",
}

class RequestDispatcher

	def initialize(session_cache, active_connections)
		@session_cache = session_cache
		@active_connections = active_connections
	end

	def dispatch(line)
		request = case(line)
							when /^\$ID/
								RequestLoginPhase1.new(line, @session_cache)
							when /^#AA/
								RequestLoginAuth.new(line, @session_cache, @active_connections)
							when /^%/
								RequestATCUpdate.new(line, @session_cache)
              when /^\$CQ/ #There are a lot of different reqests that use $CQ so there's another if loop inside of this case
                linesplit = line.split(':')
                if linesplit[2] == 'ATC'
                  RequestATCControl.new(line, @session_cache)
                elsif linesplit[2] == 'FP'
                  RequestFlightplan.new(line, @session_cache)
                elsif linesplit[2] == 'RN'
                  RequestFullName.new(line, @session_cache, @active_connections)
                elsif linesplit[2] == 'BC'
                  RequestSquawkAmend.new(line, @session_cache)
                elsif linesplit[2] == 'SC'
                  RequestScratchpadAmend.new(line, @session_cache)
                else
                  puts "WARNING: Unhandled '$CQ' line: #{line.inspect}"
                  return Response.empty
                end
              when /^#TM/
                linesplit = line.split(':')
                if linesplit[1] == '@75000'
                  RequestUserCommand.new(line, @session_cache)
                else
                  return Response.empty
                  #@active_connections.keys.each do |callsign|
                    #if linesplit[1] == callsign
                      #private_message? = true
                    #end
                  #end
                end

                  #if private_message
                    # RequestPrivateMessage.new(line, @session_cache)
                  #else
                    #puts "WARNING: Unhandled '#TM' line: #{line.inspect}"
                    #return Response.empty
                  #end
                #end
              when /^\$AM/
                RequestFlightplanAmend.new(line, @session_cache)
              when /^\$AX/
                RequestMETAR.new(line, @session_cache)
              when /^#DA/
                RequestDisconnect.new(line, @session_cache)
              else
                puts "WARNING: Unhandled line: #{line.inspect}"
                return Response.empty
							end
    puts "DEBUG: matched request: #{request.class.name}"
		valid = request.validate
		if !valid
			raise "Dispatched an invalid request for line: #{line.inspect}"
		end
    puts "DEBUG: processing #{request.class.name}"
		response = request.process
    puts "DEBUG: processing #{request.class.name} complete: #{response}"
		response
	end
end
