actions :create_db, :grant_privileges
default_action :create_db

# create_db
attribute :admin_user, kind_of: String, default: 'root'
attribute :admin_password, kind_of: String
attribute :db_name, kind_of: String

# grant_privileges
attribute :user, kind_of: String
attribute :hosts, kind_of: Array, default: ['localhost', '%']
attribute :password, kind_of: String
