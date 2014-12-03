require 'spec_helper'

describe PedantMysql2 do

  let(:connection) { ActiveRecord::Base.connection }

  before :each do
    PedantMysql2.raise_warnings!
    PedantMysql2.instance_variable_set(:@whitelist, nil)
    connection.execute('SET SESSION binlog_format = "STATEMENT"')
    if connection.execute('SHOW TABLES LIKE "comment"').size == 0
      connection.execute('CREATE TABLE comment (id int)')
    end
    connection.execute('TRUNCATE TABLE comment')
    @original_callback = PedantMysql2.on_warning
  end

  after :each do
    PedantMysql2.on_warning = @original_callback
  end

  it 'raises warnings by default' do
    expect {
      connection.execute('SELECT 1 + "foo"')
    }.to raise_error(MysqlWarning, "Truncated incorrect DOUBLE value: 'foo'")
  end

  it 'can have a whitelist of warnings' do
    PedantMysql2.ignore(/Truncated incorrect DOUBLE value/i)
    expect {
      connection.execute('SELECT 1 + "foo"')
    }.to_not raise_error
  end

  it 'do not change the returned value' do
    PedantMysql2.silence_warnings!
    result = connection.execute('SELECT 1 + "foo"')
    expect(result.to_a).to be == [[1.0]]
  end

  it 'do not change the returned value of exec_update' do
    result = connection.update('UPDATE comment SET id = 1 LIMIT 1')
    expect(result).to be_zero
  end

  it 'do not change the returned value of exec_delete' do
    result = connection.delete('DELETE FROM comment LIMIT 1')
    expect(result).to be_zero
  end

  it 'can easily be raised' do
    PedantMysql2.on_warning = lambda { |warning| raise warning }
    expect {
      connection.execute('SELECT 1 + "foo"')
    }.to raise_error(MysqlWarning)
  end

  it 'can capture the warnings generated in a block' do
    warnings = nil
    expect {
      warnings = PedantMysql2.capture_warnings do
        connection.execute('SELECT 1 + "foo"')
      end
    }.to_not raise_error
    
    expect(warnings.size).to be == 1
    expect(warnings.first).to be_a MysqlWarning
    expect(warnings.first.message).to be == "Truncated incorrect DOUBLE value: 'foo'"
  end

  it 'restores the old value that was stored in the thread_local capture_warnings' do
    Thread.current[:mysql_warnings] = 'abracadabra'
    PedantMysql2.capture_warnings do
      expect(Thread.current[:mysql_warnings]).to be_an Array
      connection.execute('SELECT 1 + "foo"')
    end
    expect(Thread.current[:mysql_warnings]).to be == 'abracadabra'
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
