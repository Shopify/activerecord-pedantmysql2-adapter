require 'active_record'
if ActiveRecord::VERSION::MAJOR >= 7 && ActiveRecord::VERSION::MINOR >= 1
  ActiveSupport::Deprecation.warn("activerecord-pedantmysql2-adapter was integrated into Rails 7.1, so is deprecated")
end

require 'pedant_mysql2'
require 'pedant_mysql2/version'
require 'active_record/connection_adapters/pedant_mysql2_adapter'
