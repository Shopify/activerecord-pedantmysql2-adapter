require 'active_record/connection_adapters/mysql2_adapter'

module ActiveRecord
  module ConnectionHandling
    def pedant_mysql2_connection(config)
      config = config.symbolize_keys

      config[:username] = 'root' if config[:username].nil?

      if Mysql2::Client.const_defined? :FOUND_ROWS
        config[:flags] = Mysql2::Client::FOUND_ROWS
      end

      client = Mysql2::Client.new(config)
      options = [config[:host], config[:username], config[:password], config[:database], config[:port], config[:socket], 0]
      ActiveRecord::ConnectionAdapters::PedantMysql2Adapter.new(client, logger, options, config)
    rescue Mysql2::Error => error
      if error.message.include?("Unknown database") && defined?(ActiveRecord::NoDatabaseError)
        raise ActiveRecord::NoDatabaseError.new(error.message, error)
      else
        raise
      end
    end
  end
end

class MysqlWarning < StandardError

  attr_reader :code, :level, :query

  def initialize(message, code, level, query)
    super(message)
    @code = code
    @level = level
    @query = query
  end

end

class ActiveRecord::ConnectionAdapters::PedantMysql2Adapter < ActiveRecord::ConnectionAdapters::Mysql2Adapter

  def execute(sql, name = nil)
    value = super
    log_warnings(sql)
    value
  end

  private

  def log_warnings(sql)
    return unless @connection.warning_count > 0

    result = @connection.query('SHOW WARNINGS')
    result.each do |level, code, message|
      warning = MysqlWarning.new(message, code, level, sql)
      ::PedantMysql2.on_warning.call(warning)
    end
  end

end
