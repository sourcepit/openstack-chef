actions :add_br, :add_port
default_action :add_br

# add_br
attribute :bridge, kind_of: String

# add_port
attribute :port, kind_of: String
