module PedantMysql2
  class << self
    attr_accessor :on_warning

    def capture_warnings
      previous_callback = on_warning
      previous_warnings = Thread.current[:mysql_warnings]
      Thread.current[:mysql_warnings] = []
      self.on_warning = lambda { |warning| Thread.current[:mysql_warnings] << warning }
      yield
      warnings = Thread.current[:mysql_warnings]
      warnings
    ensure
      Thread.current[:mysql_warnings] = previous_warnings
      self.on_warning = previous_callback
    end

    def raise_warnings!
      self.on_warning = lambda{ |warning| raise warning }
    end

    def silence_warnings!
      self.on_warning = lambda{ |*| }
    end

  end

  raise_warnings!

end
