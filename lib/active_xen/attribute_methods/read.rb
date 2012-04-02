module ActiveXen
  module AttributeMethods
    module Read
      extend ActiveSupport::Concern

      included do
        attribute_method_suffix '?'
        attribute_method_suffix '_is_read_only?'
      end

      def attribute(name)
        send(attribute) if attribute_names.include? name
      end

      def attribute?(attribute)
        send(attribute).present?
      end

      def attribute_is_read_only?(attribute)
        self._read_only_attributes.include?(attribute.to_s)
      end

      def read_attribute_for_validation(attr)
        send(attr)
      end

    protected
      def read_attribute(name)
        record[name.to_s]
      end

      def cast_attributes(record)
        record.inject({}) do |result, (name, value)|
          type_name = self._attribute_types[name.to_s]
          result[name] = type_name ? cast_attribute(value, type_name) : value
          result
        end
      end

      # Transforms an attribute value
      def cast_attribute(value, type_name)
        case type_name
        when :integer then value.to_i
        when :float then value.to_f
        when :boolean then !!value
        else value
        end
      end
    end
  end
end