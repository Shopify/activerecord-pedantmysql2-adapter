ActiveRecord::Base.configurations = {
  'test' => {
    'adapter' => 'pedant_mysql2',
    'database' => 'pedant_mysql2_test',
    'username' => 'travis',
    'encoding' => 'utf8',
    'strict' => false,
    'pool' => 5,
  }
}

ActiveRecord::Base.establish_connection(:test)
