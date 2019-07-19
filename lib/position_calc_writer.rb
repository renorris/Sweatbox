require 'geokit'
require 'mysql2'

class Leg

  def initialize(h)
    @origin = h.fetch(:origin)
    @destination = h.fetch(:destination)
		@start_time = h.fetch(:start_time)
    @miles_per_second = h.fetch(:miles_per_second)
		@complete = false
  end

	def is_done?
		@complete
	end

	def calculate_location_for_time(t)
		elapsed_time = t - @start_time
		distance = elapsed_time * @miles_per_second
    full_distance = @origin.distance_to(@destination)
		if distance >= full_distance
			@complete = true
			@destination
		else
			full_heading = @origin.heading_to(@destination)
      @origin.endpoint(full_heading, distance)
		end
	end 
end

class Route
  
  def initialize(callsign, points, knots)
    @route = points #route should be an array on waypoints as a geokit class
    @sql_client = Mysql2::Client.new(:host => "localhost", :username => "sweatbox", :password => "sweatbox", :database => 'SWEATBOX')
    @callsign = callsign
    @knots = knots
  end

  def run
    puts "Starting route for #{@callsign}"
    origin = @route[0] #The very beginning of all of the legs and waypoints
    destination = @route.last #the very last waypoint out of all of them
    amount_of_waypoints = @route.length
    working_destination = 1
    puts "origin: #{origin}, destination: #{destination}, amountofwaypoints: #{amount_of_waypoints}"

    while working_destination != amount_of_waypoints + 1

      leg_origin = @route[working_destination - 1]
      leg_destination = @route[working_destination]
      if leg_destination == nil
        leg_destination = destination
      else
      end
      mph = @knots.to_i * 1.15078
      mps = (mph / 60) / 60 
      leg = Leg.new(
        :origin => leg_origin,
        :destination => leg_destination,
        :start_time => Time.now,
        :miles_per_second => mps,
      )

      while true
        current_location = leg.calculate_location_for_time(Time.now)
        # plot it:
        coordinates = current_location.ll.split(',')
        @sql_client.query("UPDATE position_updates set groundspeed='#{@knots}',lat=#{coordinates[0]},lon=#{coordinates[1]} where callsign='#{@callsign}'")
        if leg.is_done?
          puts "Done route for #{@callsign}"
          @sql_client.query("UPDATE position_updates set groundspeed='0' where callsign='#{@callsign}'")
          break
        end
        sleep 1
      end
      working_destination += 1
    end
  end
end

#points = []
#points[0] = Geokit::LatLng.new(32.73603, -117.18539)
#points[1] = Geokit::LatLng.new(32.73423, -117.18375)
#points[2] = Geokit::LatLng.new(32.73327, -117.18407)
#points[3] = Geokit::LatLng.new(32.73106, -117.17545)
#y = Route.new("FDX460", points, 10000000)
#y.run
