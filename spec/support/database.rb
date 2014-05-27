ActiveRecord::Base.configurations = {
  'test' => {
    adapter: 'pedant_mysql2',
    database: 'pedant_mysql2_test',
    username: 'root',
    encoding: 'utf8',
    strict: false,
  },
}
ActiveRecord::Base.establish_connection(:test)
