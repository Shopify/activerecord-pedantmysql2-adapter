require 'spec_helper'

describe PedantMysql2 do

  let(:connection) { ActiveRecord::Base.connection }

  before :each do
    PedantMysql2.raise_warnings!
    PedantMysql2.instance_variable_set(:@whitelist, nil)
    PedantMysql2.ignore(/They will be merged with strict mode in a future release/)
    if connection.execute('SHOW TABLES LIKE "comment"').size == 0
      connection.execute('CREATE TABLE comment (id int)')
    end
    connection.execute('TRUNCATE TABLE comment')
    @original_callback = PedantMysql2.on_warning
  end

  after :each do
    PedantMysql2.on_warning = @original_callback
  end

  def execute_with_warning(query = 'SELECT 1 + "foo"')
    ActiveRecord::Base.connection.execute(query)
  end

  def wait_for(thread)
    sleep 0.1 until thread.stop?
  end

  # Used by the thread-safe testing
  def method_missing(method_name,*args)
    if PedantMysql2.respond_to?(method_name, true)
      PedantMysql2.send(method_name,*args)
    else
      super
    end
  end

  it 'raises warnings by default' do
    expect {
      execute_with_warning
    }.to raise_error(MysqlWarning, "Truncated incorrect DOUBLE value: 'foo'")
  end

  it 'does not raise when warning is a Note level warning e.g. unexisting table' do
    expect {
      execute_with_warning('DROP TABLE IF EXISTS `example_table`')
    }.to_not raise_error
  end

  it 'does not raise when warning is a Note level warning e.g. EXPLAIN queries' do
    expect {
      execute_with_warning('EXPLAIN SELECT 1')
    }.to_not raise_error
  end

  it 'can have a whitelist of warnings' do
    PedantMysql2.ignore(/Truncated incorrect DOUBLE value/i)
    expect {
      execute_with_warning
    }.to_not raise_error
  end

  it 'do not change the returned value' do
    PedantMysql2.silence_warnings!
    result = execute_with_warning
    expect(result.to_a).to be == [[1.0]]
  end

  it 'does not change the returned value of exec_update' do
    connection.execute('INSERT INTO comment VALUES (17)')
    result = connection.update('UPDATE comment SET id = 1 ORDER BY id LIMIT 1')
    expect(result).to be == 1
  end

  it 'does not change the returned value of exec_update when there is warnings' do
    PedantMysql2.silence_warnings!
    result = connection.update('UPDATE comment SET id = 1 WHERE id > (42+"foo") ORDER BY id LIMIT 1')
    expect(result).to be_zero
  end

  it 'does not change the returned value of exec_delete' do
    connection.execute('INSERT INTO comment VALUES (17)')
    result = connection.delete('DELETE FROM comment ORDER BY id LIMIT 1')
    expect(result).to be == 1
  end

  it 'does not change the returned value of exec_delete when there is warnings' do
    PedantMysql2.silence_warnings!
    result = connection.delete('DELETE FROM comment WHERE id > (42+"foo") ORDER BY id LIMIT 1')
    expect(result).to be_zero
  end

  it 'can easily be raised' do
    PedantMysql2.on_warning = lambda { |warning| raise warning }
    expect {
      execute_with_warning
    }.to raise_error(MysqlWarning)
  end

  it 'can capture the warnings generated in a block' do
    warnings = nil
    expect {
      warnings = PedantMysql2.capture_warnings do
        execute_with_warning
      end
    }.to_not raise_error

    expect(warnings.size).to be == 1
    expect(warnings.first).to be_a MysqlWarning
    expect(warnings.first.message).to be == "Truncated incorrect DOUBLE value: 'foo'"
  end

  it 'restores the old value that was stored in the thread_local capture_warnings' do
    warnings1 = nil
    warnings2 = nil

    warnings1 = PedantMysql2.capture_warnings do
      execute_with_warning
      warnings2 = PedantMysql2.capture_warnings do
        execute_with_warning
        execute_with_warning
      end
    end

    expect(warnings1.size).to be == 1
    expect(warnings2.size).to be == 2
    expect(warnings2).to_not include(warnings1)
  end

  it 'should be thread-safe to capture_warnings (when class instance variables were used this did not pass)' do
    thread = Thread.new do
      warnings = backup_warnings
      Thread.stop
      setup_capture
      Thread.stop
      execute_with_warning
      expect(captured_warnings.size).to be == 1
      restore_warnings(warnings)
    end

    wait_for(thread)
    warnings = backup_warnings
    thread.run
    wait_for(thread)
    setup_capture
    execute_with_warning
    expect(captured_warnings.size).to be == 1
    restore_warnings(warnings)
    thread.run
    thread.join
  end

  it 'should inherit on_warning from parent thread' do
    PedantMysql2.silence_warnings!
    thread = Thread.new do
      expect {
        execute_with_warning
      }.to_not raise_error
    end

    thread.join
  end

  describe MysqlWarning do

    subject do
      begin
        PedantMysql2.on_warning = lambda { |warning| raise warning }
        execute_with_warning
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
