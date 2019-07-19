require_relative '../response'

class RequestLoginAuth

	def initialize(line, session_cache, active_connections)
		@line = line
		@session_cache = session_cache
	  @active_connections = active_connections
  end

	def validate
		@line[0..2] == '#AA'
	end

	def process
    print "New client login request -> "
    yeti = @line.split("#AA")
    oof = yeti[1].split(":")
    @session_cache["full_name"] = oof[2]
    @session_cache["cert_id"] = oof[3]
    @session_cache["password"] = oof[4]
    @session_cache["atc_rating"] = oof[5]
    result = @session_cache['sql_client'].query("select * from certs where cert_id='#{@session_cache['cert_id']}'")
    final = []
    result.each do |cert|
      final.push cert['full_name']
    end
    if final[0] == nil
      dbname = "Not found"
    else
      dbname = final[0]
    end
    print "Name: #{oof[2]}, Cert ID: #{oof[3]}, DB Name: #{dbname}\n"

    @response = Response.new
    login_check = validate_connection
    if login_check[0]
      puts "Client successfully connected"
      @response.push("#TMSERVER:#{@session_cache["callsign"]}:#{login_check[1]}\r\n")
      @response.push("#TMSERVER:#{@session_cache["callsign"]}:Welcome, #{@session_cache['full_name'].split(" ")[0]}! You've connected to the sweatbox!\r\n")
      @response.push("#TMSERVER:#{@session_cache["callsign"]}:Callsign -> '#{@session_cache['callsign']}'. Rating -> #{ATC_RANKS[@session_cache['atc_rating'].to_i]}\r\n")
      @session_cache['logged_in?'] = true
    else
      puts "Client login details invalid"
      puts "Reason: #{login_check[1]}"
      @response.push("$ERserver:unknown:011:12:#{login_check[1]}")
      @response.set_kill_connection(true)
    end

    @response
	end

  private

  def validate_connection

    result_set = @session_cache['sql_client'].query("SELECT * FROM certs WHERE cert_id=#{@session_cache['cert_id']};")
    results = []
    result_set.each do |row|
      results.push row
    end
    user_info = results[0]
    hashed_password = Digest::SHA256.hexdigest(@session_cache['password'])
    if user_info.nil?
      [false, "The password and/or the certificate ID that you entered is invalid."]
    elsif user_info['password'] != hashed_password
      [false, "The password and/or the certificate ID that you entered is invalid."]
    elsif user_info["atc_rating"].to_i < @session_cache['atc_rating'].to_i
      [false, "The ATC Rating you specified does not match our records. Your rating on file is: #{ATC_RANKS[user_info["atc_rating"].to_i]}. Please try again."]
    elsif @active_connections[@session_cache['callsign']] != nil
      [false, "Sorry, the callsign \"#{@session_cache['callsign']}\" you requested is currently being used by another user. Please choose another callsign, and try again."]
    else
      [true, "Login Successful"]
    end

  end
end

