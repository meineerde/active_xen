require 'test_helper'

describe ActiveXen::Base do
  include ValidAttribute::Method

  class ValidateResource < ActiveXen::Base
    attribute :name
    attribute :description

    attribute :user_version, :type => :integer
    attribute :something_tiny, :type => :float
    attribute :is_awesome, :type => :boolean

    validates :name, :presence => true, :length => 4..20
  end

  describe ValidateResource do
    before { @model = ValidateResource.new }

    it "must obey validations" do
      @model.must have_valid(:name).when("Hello")
      @model.wont have_valid(:name).when("", nil, "Bad")
    end

    it "enforces the integer type" do
      @model.must have_valid(:user_version).when(1, "23", -5, "-10", 0)
      @model.wont have_valid(:user_version).when(10.5, "23.76", "", nil, "abc", [], true)
    end

    it "enforces the float type" do
      @model.must have_valid(:something_tiny).when(1, "23.2", -5.7, "-10.7", 0, -3)
      @model.wont have_valid(:something_tiny).when("", nil, "abc", [], true)
    end

    it "enforces the boolean type" do
      @model.must have_valid(:is_awesome).when(true, false)
      @model.wont have_valid(:is_awesome).when("", nil, "abc", [], 123)
    end

    it "doesn't save if invalid" do
      @model.expects(:create).never
      @model.expects(:update).never

      proc{ @model.save! }.must_raise ActiveXen::RecordInvalid
    end
  end
end