module ActiveXen
  class ConnectionPool
    class << self
      def registered_connections
        @registered_connections ||= {}
      end

      def register(id, hosts, username=nil, password=nil)
        registered_connections[id.to_s] = {
          # normalize urls
          :hosts => [hosts].flatten,
          :username => username,
          :password => password
        }
      end

      def register_config(hash)
        hash.each do |name, values|
          hosts = values['hosts']
          hosts ||= [values['host']]

          self.register(name, hosts, values['username'], values['password'])
        end
      end
    end


    def active_connections
      @active_connections ||= {}
    end

    def registered_connections
      self.class.registered_connections
    end

    def connection(id)
      active_connections[id.to_s] ||= begin
        reg = registered_connections[id.to_s]
        create_connection(reg[:hosts], reg[:username], reg[:password])
      end
    end

    def clear
      active_connections.values.each(&:logout)
      active_connections.clear
    end

  private
    def create_connection(hosts, username, password)
      ActiveXen::Connection.new(hosts, username, password)
    end
  end
end
