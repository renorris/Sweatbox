class Response

	def self.empty
		Response.new
	end

	def initialize
		@lines = []
    @broadcast_lines = []
		@db_statements = []
		@kill_connection = false
	end

	def should_respond?
		!@lines.empty?
	end

	def should_broadcast?
		!@broadcast_lines.empty?
	end

	def should_push_db?
		!@db_statements.empty?
	end

	def should_kill_connection?
		@kill_connection
	end

  def set_kill_connection(input)
    @kill_connection = input
  end

	def lines
		@lines
	end

  def push(line)
    @lines.push line.chomp
  end

  def broadcast_lines
    @broadcast_lines
  end

  def push_broadcast_line(line)
    @broadcast_lines.push line
  end

	def db_statements
		@db_statements
	end

	def push_db_statement(statement)
		@db_statements.push statement
	end

  def to_s
    "[#{self.class.name}: #{@lines.size} line(s), #{@broadcast_lines.length} broadcast line(s), #{@db_statements.size} db statement(s), should_kill_connection=#{should_kill_connection?}]"
  end

end
