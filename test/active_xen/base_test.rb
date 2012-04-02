require File.expand_path('../../test_helper', __FILE__)

describe ActiveXen::Base do
  include ValidAttribute::Method

  class SampleResource < ActiveXen::Base
    attribute :name
    attribute :description
  end

  describe "ActiveModel compliance" do
    include ActiveModel::Lint::Tests

    before { @model = SampleResource.new() }
  end

  describe "SampleResource" do
    before do
      @model = SampleResource.new(:name => "foo")
    end

    it "accepts paramaters in initialize" do
      @model.name.must_equal "foo"
      @model.description.must_be_nil
    end

    it "tells me if no attribute is set" do
      @model.name?.must_equal true
      @model.description?.must_equal false
    end
  end
end