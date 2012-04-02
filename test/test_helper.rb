require 'active_xen'

require 'minitest/matchers'
require 'minitest/autorun'
require 'valid_attribute'
require 'mocha'

module MiniTest
  module Assertions
    def require_xenserver
      unless ENV['XEN_URL']
        msg  = "An actual XenServer is required for this test. "
        msg << "You can define it with XEN_URL, XEN_USER, and XEN_PASSWORD"
        skip(msg)
      end

      url = ENV['XEN_URL']
      username = ENV['XEN_USER'] || "root"
      password = ENV['XEN_PASSWORD'] || ""

      ActiveXen::ConnectionPool.register("xenserver", url, username, password)
    end
  end
end
