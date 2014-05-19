module PedantMysql2
  class << self
    attr_accessor :on_warning
  end
  self.on_warning = lambda{ |*| }
end
