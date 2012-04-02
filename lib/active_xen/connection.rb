module ActiveXen
  class Connection
    def initialize(hosts, username=nil, password=nil)
      @hosts = hosts
      @username = username
      @password = password

      @models = {}
    end

    def model_class(base_model)
      return base_model if base_model.connection == self

      @models[base_model] ||= begin
        klass = Class.new(base_model)
        (class << klass; self; end).send(:define_method, :name){ base_model.name }
        klass.connection = self
        klass
      end
    end

    def connection
      @connection ||= ::XenApi.connect(@hosts, @username, @password, :keep_session => true, :ssl_verify => :verify_none)
    end

    def method_missing(*args, &block)
      connection.send(*args, &block)
    end
  end
end
