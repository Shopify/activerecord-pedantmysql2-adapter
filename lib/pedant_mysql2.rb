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
      self.on_warning = nil
    end

    def ignore(*matchers)
      self.whitelist.concat(matchers.flatten)
    end

    def ignored?(warning)
      on_warning.nil? || whitelist.any? { |matcher| matcher =~ warning.message }
    end

    protected

    def whitelist
      @whitelist ||= []
    end

  end

  raise_warnings!

end
