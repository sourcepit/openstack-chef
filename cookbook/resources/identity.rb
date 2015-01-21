actions :create_user
default_action :create_user

attribute :auth_uri, kind_of: String

attribute :admin_tenant, kind_of: String
attribute :admin_user, kind_of: String
attribute :admin_password, kind_of: String

attribute :user, kind_of: String
attribute :password, kind_of: String