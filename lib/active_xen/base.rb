module ActiveXen
  module Models
    # this module contains the pre-defined model classes
  end

  class Base
    extend ActiveModel::Naming
    extend ActiveModel::Translation
    include ActiveModel::MassAssignmentSecurity

    class_attribute :connection, :instance_writer => false, :instance_reader => false
    self.connection = nil

    class << self
      # This sets the connection to use for this class and all refenences to dependent objects
      # As we don't assume a certain connection to be used by default you always HAVE to use
      # this for your entry point to the models.
      #
      # Example Usage:
      #
      #   hosts = ["https://master.example.com", "https://slave.example.com"]
      #   ActiveXen::ConnectionPool.register("default", hosts, "root", "supersecret")
      #   pool = ActiveXen::ConnectionPool.new
      #   all_vms = VM.on(pool.connection("default")).all

      def on(connection)
        if !connection || connection == self.connection
          return self
        else
          connection.model_class(self)
        end
      end
    end

    def initialize(attributes = nil, options = {})
      @record = nil
      @persisted = false
      @destroyed = false

      @changed_attributes = {}

      case attributes
      when String
        @ref = attributes.dup.freeze
        @persisted = true
      when Hash
        assign_attributes(attributes, options)
      end

      yield self if block_given?
      # run_callbacks :initialize
    end
    attr_reader :ref

    def to_ref
      ref || "OpaqueRef:NULL"
    end

    def to_param
      uuid && uuid.to_s
    end

    # Allows you to set all the attributes at once by passing in a hash with keys
    # matching the attribute names (which again matches the column names).
    #
    # If any attributes are protected by either +attr_protected+ or
    # +attr_accessible+ then only settable attributes will be assigned.
    #
    #   class User < XenAdmin::XenAPI::Base
    #     attr_protected :is_admin
    #   end
    #
    #   user = User.new
    #   user.attributes = { :username => 'Phusion', :is_admin => true }
    #   user.username   # => "Phusion"
    #   user.is_admin?  # => false
    def attributes=(new_attributes)
      return unless new_attributes.is_a? Hash
      assign_attributes(new_attributes)
    end

    def assign_attributes(new_attributes, options = {})
      return unless new_attributes

      new_attributes.stringify_keys.each do |k, v|
        # don't frown upon read-only attributes, just skip those.
        next if respond_to?("#{k}_is_read_only?") && send("#{k}_is_read_only?")

        if respond_to?("#{k}=")
          send("#{k}=", v)
        else
          raise ActiveXen::UnknownAttributeError, "unknown attribute: #{k}"
        end
      end
    end

    # Freeze the attributes hash such that associations are still accessible, even on destroyed records.
    def freeze
      @attributes.freeze; self
    end

    # Returns +true+ if the attributes hash has been frozen.
    def frozen?
      @attributes.frozen?
    end

    def inspect
      attrs = (@record ||{}).inject({}) do |result, (name, value)|
        value = "#<#{value.class.name}: #{value.to_ref}>" if value.respond_to?(:to_ref)
        result[name] = value
        result
      end

      "#<#{self.class.name}: #{self.to_ref} record=#{attrs.inspect}>"
    end
  end

  Base.class_eval do
    include ActiveModel::Conversion

    include Persistence
    extend ActiveModel::Translation
    extend ActiveModel::Naming
    include Validations

    include AttributeMethods
    include AttributeMethods::Read, AttributeMethods::Write, AttributeMethods::Dirty

    # we always have a read_only uuid
    read_only_attribute 'uuid'
  end
end
