module ActiveXen
  module Lazy
    extend ActiveSupport::Concern

    included do
      class_attribute :_lazy_attributes, :instance_writer => false
      self._lazy_attributes = []

      class_attribute :_lively_attributes, :instance_writer => false
      self._lively_attributes = []
    end

    module ClassMethods
      # Registers lazy attributes. If one of these attributes is requested,
      # the object is lazily loaded from the backend server. If this is set,
      # all other attributes are considered lively, irregardless of the
      # +lively_attributes+ setting.
      def lazy_attributes(*args)
        self._lazy_attributes += args.collect(&:to_s)
      end


      # Register attributes that are lively, i.e. not lazy.
      # These attributes don't trigger a load operation from the backend
      # service. By default, all attributes are considered lazy, except the
      # ones defined here.
      def lively_attributes(*args)
        self._active_attributes += args.collect(&:to_s)
      end
    end

  protected
    def read_attribute(name)
      name = name.to_s

      if self._lazy_attributes.empty?
        load_object unless self._lively_attributes.include?(name)
      else
        load_object if self._lazy_attributes.include?(name)
      end

      super
    end
  end
end