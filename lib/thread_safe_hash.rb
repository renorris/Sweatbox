class ThreadSafeHash

  def initialize
    @data = {}
    @mutex = Mutex.new
  end

  def [](key)
    get(key)
  end

  def get(key)
    @mutex.synchronize do
      @data[key]
    end
  end

  def []=(key, value)
    set(key, value)
  end

  def set(key, value)
    @mutex.synchronize do
      @data[key] = value
    end
  end

  def each_key_with_index(&block)
    @mutex.synchronize do
      @data.keys.each_with_index do |key, i|
        block.call(key, i)
      end
    end
  end
  
  def each(&block)
    @mutex.synchronize do
      @data.each do |key, value|
        block.call(key, value)
      end
    end
  end

  def delete(key)
    @mutex.synchronize do
      @data.delete(key)
    end
  end

  def using(&block)
    @mutex.synchronize do
      block.call(@data)
    end
  end

end

