class BroadcastLine

	def initialize(data, type)
		@data = data.chomp
    @type = type
	end

	def data
		@data
	end
  
  def set_data(data)
    @data = data
  end

  def type
    @type
  end

end
