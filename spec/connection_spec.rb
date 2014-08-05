require 'spec_helper'

class Mock
  include ActiveRecord::ConnectionHandling
  def logger
    nil
  end
end

describe ActiveRecord::ConnectionHandling do

  it 'raises NoDatabaseError correctly' do
    expect {
      Mock.new.pedant_mysql2_connection({host: 'localhost', database: 'nosuchthing'})
    }.to raise_error(ActiveRecord::NoDatabaseError)
  end

end
