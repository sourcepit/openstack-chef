actions :create_user, :user_role_add
default_action :create_user

attribute :auth_uri, kind_of: String

attribute :admin_tenant, kind_of: String
attribute :admin_user, kind_of: String
attribute :admin_password, kind_of: String

# create_user
attribute :user, kind_of: String
attribute :password, kind_of: String

# user_role_add
attribute :tenant, kind_of: String
attribute :role, kind_of: String