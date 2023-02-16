require 'spec_helper'

class Mock
  include ActiveRecord::ConnectionHandling
  def logger
    nil
  end
end

describe ActiveRecord::ConnectionHandling do

  it 'raises NoDatabaseError correctly' do
    error_class = defined?(ActiveRecord::NoDatabaseError) ? ActiveRecord::NoDatabaseError : Mysql2::Error
    expect {
      Mock.new.pedant_mysql2_connection({
        host: TestSupport::DB_CONFIG['hostname'],
        username: TestSupport::DB_CONFIG['username'],
        password: TestSupport::DB_CONFIG['password'],
        database: 'nosuchthing',
      })
    }.to raise_error(error_class)
  end

  if ActiveRecord.gem_version >= Gem::Version.new("7.1")
    it 'raises deprecation warning on Active Record 7.1 and above' do
      expect(ActiveSupport::Deprecation).to receive(:warn).with(/`activerecord-pedantmysql2-adapter` is deprecated/)
      Mock.new.pedant_mysql2_connection({
        host: TestSupport::DB_CONFIG['hostname'],
        username: TestSupport::DB_CONFIG['username'],
        password: TestSupport::DB_CONFIG['password'],
        database: TestSupport::DB_CONFIG['database'],
      })
    end
  end
end
