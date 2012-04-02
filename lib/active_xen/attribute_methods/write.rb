module ActiveXen
  module AttributeMethods
    module Write
      extend ActiveSupport::Concern

    protected
      def write_attribute(name, value)
        record[name.to_s] = value
      end

      # transforms the attribute value into the form usable by the underlying
      # API
      def uncast_attribute(value, type_name)
        case type_name
        when :integer then value.to_s
        when :float then value.to_s
        when :boolean then !!value
        else value
        end
      end
    end
  end
end