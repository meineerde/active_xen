module ActiveXen
  module Models
    class HostCPU < ActiveXen::Base
      self.xen_class = 'host_cpu'
    end
  end
end