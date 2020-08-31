ActiveRecord::Base.establish_connection(
  'adapter' => 'pedant_mysql2',
  'database' => 'pedant_mysql2_test',
  'username' => 'root',
  'encoding' => 'utf8',
  'host' => 'localhost',
  'strict' => false,
  'pool' => 5,
)
