module PedantMysql2
  class << self
    attr_accessor :on_warning

    def silence_warnings
      previous_value = Thread.current[:silence_warnings]
      Thread.current[:silence_warnings] = true
      yield
    ensure
      Thread.current[:silence_warnings] = previous_value
    end

    def silence_warnings?
      Thread.current[:silence_warnings]
    end

  end
  self.on_warning = lambda{ |*| }
end
