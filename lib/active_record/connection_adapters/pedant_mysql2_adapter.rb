require 'active_record/connection_adapters/mysql2_adapter'

module ActiveRecord
  module ConnectionHandling
    if ConnectionAdapters::Mysql2Adapter.respond_to?(:new_client)
      def pedant_mysql2_connection(config)
        raise_pedant_deprecation_warning

        config = config.symbolize_keys
        config[:flags] ||= 0

        if config[:flags].kind_of? Array
          config[:flags].push "FOUND_ROWS"
        else
          config[:flags] |= Mysql2::Client::FOUND_ROWS
        end

        ConnectionAdapters::PedantMysql2Adapter.new(
          ConnectionAdapters::Mysql2Adapter.new_client(config),
          logger,
          nil,
          config,
        )
      end
    else
      def pedant_mysql2_connection(config)
        raise_pedant_deprecation_warning

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
          raise ActiveRecord::NoDatabaseError.new(error.message)
        else
          raise
        end
      end
    end

    def raise_pedant_deprecation_warning
      if ActiveRecord.gem_version >= Gem::Version.new("7.1")
        ActiveSupport::Deprecation.warn(<<~MSG.squish)
          `activerecord-pedantmysql2-adapter` is deprecated. SQL warning behaviour is available in Active Record,
          starting in version 7.1. This gem will soon be archived. Please migrate to the upstream behaviour:
          https://edgeguides.rubyonrails.org/configuring.html#config-active-record-db-warnings-action.
        MSG
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
  def execute(sql, *)
    value = super
    log_warnings(sql)
    value
  end
  ruby2_keywords :execute if respond_to?(:ruby2_keywords, true)

  def exec_delete(sql, name, binds)
    @affected_rows_before_logging = nil
    value = super
    @affected_rows_before_logging || value
  end

  alias :exec_update :exec_delete

  private

  def log_warnings(sql)
    # support for https://github.com/rails/rails/commit/d86fd6415c0dfce6fadb77e74696cf728e5eb76b
    connection = instance_variable_defined?(:@raw_connection) ? @raw_connection : @connection

    return unless connection.warning_count > 0

    @affected_rows_before_logging = connection.affected_rows
    result = connection.query('SHOW WARNINGS')

    result.each do |level, code, message|
      warning = MysqlWarning.new(message, code, level, sql)
      ::PedantMysql2.warn(warning)
    end
  end
end

if ActiveRecord::VERSION::MAJOR == 3
  ActiveRecord::Base.extend(ActiveRecord::ConnectionHandling)
end
