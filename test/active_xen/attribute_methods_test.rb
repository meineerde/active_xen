require 'test_helper'

describe ActiveXen::AttributeMethods do
  class AttributeList < ActiveXen::Base
    attribute "an_attribute"
    read_only_attribute "read_only"
  end

  before do
    XenApi::Client.any_instance.stubs(:_do_call).with("session.login_with_password", ["root", "secure"]).returns("session")

    ActiveXen::ConnectionPool.register('test', ['https://example.com/', 'https://test.com/'], "root", "secure")
    @pool = ActiveXen::ConnectionPool.new
    @connection = @pool.connection('test')
    @model = AttributeList.on(@connection).new
  end

  it "creates attributes" do
    @model.attribute_names.must_include "read_only"
    @model.attribute_names.must_include "an_attribute"

    @model.an_attribute.must_equal nil
    @model.an_attribute = "foo"
    @model.an_attribute.must_equal "foo"
  end

  it "allows to redefine attribute getters and setters" do
    class CustomAttributes < ActiveXen::Base
      attribute "custom_attribute" do
        get { @custom_attribute ||= "Hello" }
        set { |value| @custom_attribute = "Hello, #{value}" }
      end
    end
    @model = CustomAttributes.on(@connection).new

    @model.custom_attribute.must_equal "Hello"
    @model.custom_attribute = "Stranger"
    @model.custom_attribute.must_equal "Hello, Stranger"
  end

  it "allows to define read-only attributes" do
    @model.read_only_attributes.must_include "read_only"
    @model.read_only_attributes.wont_include "an_attribute"
  end

  it "doesn't allow to set read_only attributes" do
    @model.read_only.must_equal nil
    proc {@model.read_only= "foo"}.must_raise NoMethodError
    @model.read_only.must_equal nil
  end

  it "answers to has_attribute?" do
    @model.has_attribute?("an_attribute").must_equal true
    @model.has_attribute?("not_existing").must_equal false
  end

  it "defines attribute lists" do
    @model.attributes.must_equal({
      "an_attribute" => nil,
      "read_only" => nil,
      "uuid" => nil
    })
  end

  describe "#model_instance" do
    it "handles null reference" do
      @model.model_instance("OpaqueRef:NULL", "AttributeList").must_equal nil
    end

    it "creates a new instance for a ref" do
      inst = @model.model_instance("OpaqueRef:FooBar", "VM")
      inst.must_be_kind_of ActiveXen::Models::VM
      inst.to_ref.must_equal "OpaqueRef:FooBar"
      inst.must_be :persisted?
    end

    it "is transparent for existing model instances" do
      @model.model_instance(@model, "AttributeList").must_equal @model
    end
  end
end
