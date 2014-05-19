ActiveRecord::Base.configurations = {
  'test' => {
    adapter: 'pedant_mysql2',
    database: 'pedant_mysql2_test',
    username: nil,
    port: '13306',
    host: '127.0.0.1',
    encoding: 'utf8',
    strict: false,
  },
}
ActiveRecord::Base.establish_connection(:test)
