module ActiveXen
  module Enum
    def get(value)
      self.const_get(value.camelize)
    end
  end
end