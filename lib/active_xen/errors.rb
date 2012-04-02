# Raised by XenAdmin::XenAPI::Base.save! and XenAdmin::XenAPI::Base.create!
# methods when record cannot be saved because record is invalid.

module ActiveXen
  GenericError = ::XenApi::Errors::GenericError

  # Raised by XenAdmin::XenAPI::Base.save! and XenAdmin::XenAPI::Base.create!
  # when record cannot be saved because record is invalid.
  class RecordNotSaved < GenericError; end

  class ConnectionMissingError < GenericError; end

  class UnknownAttributeError < GenericError; end

end