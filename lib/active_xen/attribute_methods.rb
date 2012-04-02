require 'active_support/core_ext/class/attribute'

module ActiveXen
  module AttributeMethods
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    class Accessor
      def initialize(proc=nil, &block)
        proc = block if block_given?
        proc.arity == 1 ? proc.call(self) : instance_eval(&proc) if proc
      end

      %w[get set save create update].each do |method|
        self.module_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method}(&block)
            if block_given?
              @#{method} = block
            else
              @#{method}
            end
          end

          def #{method}=(proc)
            @#{method} = proc
          end
        RUBY
      end
    end

    included do
      # Keep a list of defined attributes.
      # These can be either read-only or read-write
      class_attribute :_read_write_attributes, :instance_writer => false
      self._read_write_attributes = []
      class_attribute :_read_only_attributes, :instance_writer => false
      self._read_only_attributes = []

      class_attribute :_attribute_types, :instance_writer => false
      self._attribute_types = {}

      # Array of Modules to search for a model class to instanciate
      class_attribute :model_path, :instance_reader => false, :instance_writer => false
      self.model_path = [ActiveXen::Models]
    end

    module ClassMethods
      # Registers a read-write attribute.
      # The getter and setter can be customized:
      #
      #     class VM < ActiveXen::Base
      #       attribute :my_attribute do
      #         get { get_attribute(:my_attribute) }
      #         set {|value| set_attribute(:my_attribute, value) }
      #       end
      #     end
      def attribute(name, options_or_accessor=nil, accessor=nil, &block)
        if accessor ||  options_or_accessor.is_a?(Hash)
          options = options_or_accessor || {}
        else
          options = {}
        end
        accessor ||= Accessor.new(block)
        name = name.to_s

        attr_accessors.send :define_method, name do
          value = read_attribute(name)
          value.nil? ? options[:default] : value
        end unless attr_accessors.instance_methods.include?(name)

        attr_accessors.send :define_method, :"#{name}=" do |value|
          write_attribute(name, value)
        end unless attr_accessors.instance_methods.include?("#{name}=")

        accessor ||= Accessor.new(block)
        self.send(:define_method, name, accessor.get) if accessor.get
        self.send(:define_method, :"#{name}=", accessor.set) if accessor.set

        %w[save update create].each do |meth|
          if accessor.send(meth)
            attr_accessors.send(:define_method, :"#{name}_#{meth}!", accessor.send(meth))
          end
        end

        enforce_type(name, options[:type]) if options[:type]

        define_attribute_method name
        self._read_write_attributes |= [name.to_s]

        nil
      end

      # Registers a read-only attribute.
      # Pass a block to customize the getter.
      def read_only_attribute(name, options={}, &block)
        name = name.to_s

        attr_accessors.send :define_method, name do
          value = read_attribute(name)
          value.nil? ? options[:default] : value
        end unless attr_accessors.instance_methods.include?(name)
        self.send :define_method, name, &block if block_given?

        enforce_type(name, options[:type]) if options[:type]

        define_attribute_method name
        self._read_only_attributes |= [name]

        nil
      end

      def has_one(name, options={}, accessor=nil, &block)
        model_name = options[:class_name] || name

        attr_accessors.send :define_method, name do
          value = read_attribute(name)
          return value if value.nil?
          value = model_instance(value, model_name)

          # save the created object but don't trigger the dirty flag
          record[name.to_s] = value
        end unless attr_accessors.instance_methods.include?(name)

        accessor ||= Accessor.new(block)
        if options[:read_only]
          if accessor.get
            read_only_attribute(name, &(accessor.get))
          else
            read_only_attribute(name)
          end
        else
          attribute(name, accessor)
        end
      end

      def has_many(name, options={}, accessor=nil, &block)
        model_name = options[:class_name] || name

        attr_accessors.send :define_method, name do
          values = read_attribute(name) || []
          record[name.to_s] = values.collect do |value|
            model_instance(value, model_name)
          end

          # save the created object but don't trigger the dirty flag
          record[name.to_s] = values
        end unless attr_accessors.instance_methods.include?(name)

        accessor ||= Accessor.new(block)
        if options[:read_only]
          if accessor.get
            read_only_attribute(name, &(accessor.get))
          else
            read_only_attribute(name)
          end
        else
          attribute(name, accessor)
        end
      end

      def enforce_type(attr_name, type_name)
        case type_name
        when :integer
          validates_numericality_of attr_name, :only_integer => true
        when :float
          validates_numericality_of attr_name
        when :boolean
          validates_inclusion_of attr_name, :in => [true, false]
        end

        types = self._attribute_types.dup
        types[attr_name] = type_name
        self._attribute_types = types

        nil
      end

      def model_from_name(name, ensure_connection=true)
        name = name.to_s

        mod = self.model_path.find{ |mod| mod.const_defined?(name) }
        model = mod.const_get(name) if mod
        model ||= name.constantize

        if ensure_connection && model.connection != self.connection
          model = model.on(self.connection)
        end
        model
      end

    protected

      # ActiveModel 3.2 only checks for it's own implemented attribute methods
      def instance_method_already_implemented?(method_name)
        super ||
        attr_accessors.method_defined?(method_name)
      end

      def attr_accessors
        @attr_accessors ||= begin
          mod = Module.new
          include mod
          mod
        end
      end
    end

    # Returns a hash of all the attributes with their names as keys and the values of the attributes as values.
    def attributes
      read_only_attributes.merge read_write_attributes
    end

    def read_write_attributes
      self._read_write_attributes.inject({}) do |hash, attr|
        hash[attr.to_s] = send(attr)
        hash
      end
    end

    def read_only_attributes
      self._read_only_attributes.inject({}) do |hash, attr|
        hash[attr.to_s] = send(attr)
        hash
      end
    end

    # Returns true if the given attribute is in the attributes hash
    def has_attribute?(attr_name)
      self.attribute_names.include?(attr_name.to_s)
    end

    # Returns an array of names for the attributes available on this object.
    def attribute_names
      (self._read_only_attributes + self._read_write_attributes).uniq
    end

    def model_instance(ref_or_model, model_name)
      if ref_or_model == "OpaqueRef:NULL"
        # a null ref
        nil
      elsif ref_or_model.is_a?(String)
        # the saved value is a ref
        klass = self.class.model_from_name(model_name)
        klass.new(ref_or_model)
      else
        ref_or_model
      end
    end

  protected
    # Overwritten from ActiveModel::AttributeMethods::attribute_method?
    def attribute_method?(attr_name)
      respond_to_without_attributes?(:attributes) && attribute_names.include?(attr_name)
    end

  end
end