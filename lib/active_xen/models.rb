module ActiveXen
  module Models
    class << self
      def use_relative_model_naming?
        true
      end
    end
  end
end

require 'active_xen/models/host'
require 'active_xen/models/host_cpu'
require 'active_xen/models/vm'
