require_relative "../response"

class RequestLoginPhase1

	def initialize(line, session_cache)
		@line = line
		@session_cache = session_cache
	end

	def validate
		@line[0..2] == '$ID'
	end

	def process
		print "New client ident: "
		g = @line.split("$ID")
		e = g[1].split(":")
		@session_cache['callsign'] = e[0]
		@session_cache["client_name"] = e[3]
		@session_cache["uuid"] = SecureRandom.hex[0..8]
		print "Callsign #{e[0]} on #{e[3]}\n"
		Response.empty
	end

end

