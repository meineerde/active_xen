module ActiveXen
  class RecordInvalid < GenericError; end

  module Validations
    extend ActiveSupport::Concern
    include ActiveModel::Validations

    # The validation process on save can be skipped by passing <tt>:validate => false</tt>. The regular Base#save method is
    # replaced with this when the validations module is mixed in, which it is by default.
    def save(options={})
      perform_validations(options) ? super : false
    end

    # Attempts to save the record just like Base#save but will raise a +RecordInvalid+ exception instead of returning false
    # if the record is not valid.
    def save!(options={})
      perform_validations(options) ? super : raise(RecordInvalid.new(self))
    end

    # Runs all the validations within the specified context. Returns true if no errors are found,
    # false otherwise.
    #
    # If the argument is false (default is +nil+), the context is set to <tt>:create</tt> if
    # <tt>new?</tt> is true, and to <tt>:update</tt> if it is not.
    #
    # Validations with no <tt>:on</tt> option will run no matter the context. Validations with
    # some <tt>:on</tt> option will only run in the specified context.
    def valid?(context = nil)
      context ||= (new? ? :create : :update)
      output = super(context)
      errors.empty? && output
    end

  protected

    def perform_validations(options={})
      perform_validation = options[:validate] != false
      perform_validation ? valid?(options[:context]) : true
    end
  end
end