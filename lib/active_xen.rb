require 'xenapi'
require 'active_support'
require 'active_support/core_ext'
require 'active_model'

module ActiveXen
end

require 'active_xen/errors'
# require 'active_xen/lazy'
require 'active_xen/persistence'
require 'active_xen/validations'

require 'active_xen/attribute_methods'
require 'active_xen/attribute_methods/dirty'
require 'active_xen/attribute_methods/read'
require 'active_xen/attribute_methods/write'

require 'active_xen/connection_pool'
require 'active_xen/connection'
require 'active_xen/base'
require 'active_xen/models'

require "active_xen/version"