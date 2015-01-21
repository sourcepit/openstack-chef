actions :tenant_create, :user_create, :role_create, :user_role_add, :service_create, :endpoint_create
default_action :tenant_create

attribute :auth_uri, kind_of: String

attribute :admin_tenant, kind_of: String
attribute :admin_user, kind_of: String
attribute :admin_password, kind_of: String
# or
attribute :admin_token, kind_of: String

# tenant_create
attribute :tenant_name, kind_of: String
attribute :tenant_description, kind_of: String

# user_create
attribute :user, kind_of: String
attribute :password, kind_of: String

# role_create, user_role_add
attribute :role, kind_of: String

# service_create
attribute :service_name, kind_of: String
attribute :service_type, kind_of: String
attribute :service_description, kind_of: String

# endpoint_create
attribute :endpoint_url, kind_of: String
attribute :endpoint_admin_url, kind_of: String # optional
attribute :endpoint_region, kind_of: String