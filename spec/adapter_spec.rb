require 'spec_helper'

describe PedantMysql2 do

  let(:connection) { ActiveRecord::Base.connection }

  before :each do
    connection.execute('SET SESSION binlog_format = "STATEMENT"')
    connection.execute('CREATE TABLE IF NOT EXISTS comment (id int)')
    connection.execute('TRUNCATE TABLE comment')
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

  it 'can allow blocks of queries to be silenced' do
    PedantMysql2.on_warning = lambda do |warning|
      raise warning unless PedantMysql2.silence_warnings?
    end
    expect {
      PedantMysql2.silence_warnings do
        expect(PedantMysql2.silence_warnings?).to be true
        connection.execute('SELECT 1 + "foo"')
      end
    }.to_not raise_error
  end

  it 'restores the old value that was stored in the thread_local silence_warnings' do
    Thread.current[:silence_warnings] = 'abracadabra'
    PedantMysql2.silence_warnings do
      expect(Thread.current[:silence_warnings]).to be true
      connection.execute('SELECT 1 + "foo"')
    end
    expect(Thread.current[:silence_warnings]).to be == 'abracadabra'
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
