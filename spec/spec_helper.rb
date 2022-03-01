lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rspec/its'
require 'activerecord-pedantmysql2-adapter'

module TestSupport
  DB_CONFIG = {
    'adapter' => 'pedant_mysql2',
    'database' => 'pedant_mysql2_test',
    'username' => 'root',
    'password' => ENV['CI'] ? 'root' : nil,
    'encoding' => 'utf8mb4',
    'host' => 'localhost',
    'strict' => false,
    'pool' => 5,
  }.freeze
end

ActiveRecord::Base.establish_connection(TestSupport::DB_CONFIG)

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support', '**', '*.rb'))].each { |f| require f }

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end
