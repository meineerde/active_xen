module ActiveXen
  module Persistence
    extend ActiveSupport::Concern

    included do
      class_attribute :xen_class, :instance_writer => false
      self.xen_class = nil
    end

    module ClassMethods
      def build(attributes={})
        self.new(attributes)
      end

      def create(attributes = {})
        self.new(attributes).tap { |resource| resource.save }
      end

      # Create a new instance from a raw object reference and record
      # This is intended to be used internally.
      # You should never rely on the object structure of the internal record
      def from_record(ref, record)
        obj = self.new(ref)

        # This smells, but we don't want to actually expose the internal record
        obj.instance_variable_set("@record", record)
        obj
      end

      def find(scope, options={})
        case scope
        when :all   then find_every(options)
        when :first then find_first(options)
        when :last  then find_last(options)
        when Hash
          case
          when scope.has_key?(:name_label)
            find_by_name_label(scope[:name_label], options)
          when scope.has_key?(:uuid)
            find_by_uuid(scope[:uuid], options)
          end
        else
          find_by_uuid(scope, options)
        end
      end

      def find_first(options={})
        obj = proxy.get_all.first{ |ref| self.new(ref) }
        options.fetch(:lazy, true) ? obj : obj.reload
      end
      alias :first :find_first

      def find_last(options={})
        obj = proxy.get_all.last{ |ref| self.new(ref) }
        options.fetch(:lazy, true) ? obj : obj.reload
      end
      alias :last :find_last

      def find_every(options={})
        if options.fetch(:lazy, true)
          proxy.get_all.collect{ |ref| self.new(ref) }
        else
          proxy.get_all_records.collect{ |ref, record| self.from_record(ref, record) }
        end
      end
      alias :get_all :find_every
      alias :all :find_every

      # Gets a lazy object by it's name_label
      # As the name_label is not guaranteed to be unique, we return an array.
      def find_by_name_label(name_label, options={})
        proxy.get_by_name_label(name_label).collect do |ref|
          obj = self.new(ref)
          options.fetch(:lazy, true) ? obj : obj.reload
        end
      end
      alias :get_by_name_label :find_by_name_label

      # Gets a lazy object by it's uuid
      # Returns a single object
      def find_by_uuid(uuid, options={})
        ref = proxy.get_by_uuid(uuid)
        obj = self.new(ref)
        options.fetch(:lazy, true) ? obj : obj.reload
      end
      alias :get_by_uuid :find_by_uuid

      # The low-level proxy object for interfacing with XenServer
      def proxy
        if self.connection
          self.connection.send(self.xen_class)
        else
          raise ActiveXen::ConnectionMissingError.new("You need to define a connection for this model.")
        end
      end
    end

    def new?
      !persisted?
    end

    def persisted?
      !!@ref
    end

    def loaded?
      !@record.nil?
    end

    def destroyed?
      @destroyed
    end

    def save(options = {})
      save!(options)
    rescue XenApi::Errors::GenericError
      false
    end

    def save!(options = {})
      new? ? create(options) : update(options)
    end

    def destroy
      if persisted?
        proxy.destroy self.to_ref
      end

      @destroyed = true
      freeze
    rescue GenericError
      # TODO: Handle errors here. Most can probably be ignored
      raise
    end

    def reload
      load_record
      self
    end

  protected
    def create(options={})
      proxy_record = self.read_write_attributes.inject({}) do |proxy_record, (name, value)|
        unless self.respond_to?(:"#{name}_save!") ||
               self.respond_to?(:"#{name}_create!") ||
               value.nil?

          if self._attribute_types.has_key? name
            value = uncast_attribute(value, self._attribute_types[name])
          elsif value.respond_to?(:to_ref)
            value = value.to_ref
          end
          proxy_record[name] = value
        end
        proxy_record
      end

      # create the object and save the ref
      # We are now officially persisted
      ref = proxy.create(proxy_record)
      @ref = ref.dup.freeze

      # Handle the attributes with a special save method
      self.changed_attributes.each do |name, value|
        # read-only attributes should never be saved
        next if self._read_only_attributes.include?(name)

        if self.respond_to?(:"#{name}_create!")
          send("#{name}_create!")
        elsif self.respond_to?(:"#{name}_save!")
          send("#{name}_save!")
        end
      end

      @record = nil
      true
    rescue GenericError
      # TODO: do something with the error
      # TODO: Try a rollback?
      raise
    end

    def update(optione={})
      self.changed_attributes.each do |name, value|
        # read-only attributes should never be saved
        next if self._read_only_attributes.include?(name)

        if self.respond_to?(:"#{name}_update!")
          send("#{name}_update!")
        elsif self.respond_to?(:"#{name}_save!")
          send("#{name}_save!")
        else
          if self._attribute_types.has_key? name
            value = uncast_attribute(value, self._attribute_types[name])
          elsif value.respond_to?(:to_ref)
            value = value.to_ref
          end
          proxy.send("set_#{name}", value)
        end
      end
      true
    rescue GenericError
      # TODO: do something with the error.
      # TODO: Try a rollback?
      raise
    end

    def record
      load_record unless loaded?
      @record
    end

    def proxy
      self.class.proxy
    end

    # load the object from the backend storage
    def load_record
      if persisted?
        @record = proxy.get_record(ref)
        # create proper variables from the underlying proxy structure
        @record = cast_attributes(@record)
      else
        @record = {}
      end
    rescue
      # TODO: Hmmmm, I should probably do something here
      raise
    end

  end
end
