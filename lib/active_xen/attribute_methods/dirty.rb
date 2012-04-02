module ActiveXen
  module AttributeMethods
    module Dirty
      extend ActiveSupport::Concern
      include ActiveModel::Dirty

      def save!(*)
        changes = self.changes

        super.tap do
          @previously_changed = changes
          @changed_attributes.clear
        end
      end

      def reload
        super.tap do
          @previously_changed.clear
          @changed_attributes.clear
        end
      end

    protected
      # Wrap write_attribute to remember original attribute value.
      def write_attribute(name, value)
        name = name.to_s

        # The attribute already has an unsaved change.
        if attribute_changed?(name)
          old = changed_attributes[name]
          changed_attributes.delete(name) unless field_changed?(name, old, value)
        else
          attribute_will_change(name) if field_changed?(name, old, value)
        end

        # Carry on.
        super(name, value)
      end

      def field_changed?(name, old, value)
        old != value
      end
    end
  end
end