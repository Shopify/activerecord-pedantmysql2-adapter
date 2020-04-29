require 'active_record/connection_adapters/mysql2_adapter'

module ActiveRecord
  module ConnectionHandling
    def pedant_mysql2_connection(config)
      config = config.symbolize_keys
      config[:flags] ||= 0

      if config[:flags].kind_of? Array
        config[:flags].push "FOUND_ROWS"
      else
        config[:flags] |= Mysql2::Client::FOUND_ROWS
      end

      ActiveRecord::ConnectionAdapters::PedantMysql2Adapter.new(nil, logger, nil, config)
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

  def exec_delete(sql, name, binds)
    @affected_rows_before_logging = nil
    value = super
    @affected_rows_before_logging || value
  end

  alias :exec_update :exec_delete

  private

  def log_warnings(sql)
    return unless @connection.warning_count > 0

    @affected_rows_before_logging = @connection.affected_rows
    result = @connection.query('SHOW WARNINGS')

    result.each do |level, code, message|
      warning = MysqlWarning.new(message, code, level, sql)
      ::PedantMysql2.warn(warning)
    end
  end
end

if ActiveRecord::VERSION::MAJOR == 3
  ActiveRecord::Base.extend(ActiveRecord::ConnectionHandling)
end
