require 'spec_helper'

describe PedantMysql2 do

  let(:connection) { ActiveRecord::Base.connection }

  before :each do
    @original_callback = PedantMysql2.on_warning
  end

  after :each do
    PedantMysql2.on_warning = @original_callback
  end

  it 'just do nothing by default' do
    expect {
      connection.execute('SELECT 1 + "foo"')
    }.to_not raise_error
  end

  it 'do not change the returned value' do
    result = connection.execute('SELECT 1 + "foo"')
    expect(result.to_a).to be == [[1.0]]
  end

  it 'can easily be raised' do
    PedantMysql2.on_warning = lambda { |warning| raise warning }
    expect {
      connection.execute('SELECT 1 + "foo"')
    }.to raise_error(MysqlWarning)
  end

  describe MysqlWarning do

    subject do
      begin
        PedantMysql2.on_warning = lambda { |warning| raise warning }
        connection.execute('SELECT 1 + "foo"')
      rescue MysqlWarning => exception
        exception
      end
    end

    its(:message) { should be == "Truncated incorrect DOUBLE value: 'foo'" }

    its(:code) { should be == 1292 }

    its(:level) { should be == 'Warning' }

    its(:query) { should be == 'SELECT 1 + "foo"' }
  end

end
