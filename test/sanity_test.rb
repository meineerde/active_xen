require 'test_helper'

class SanityTest < MiniTest::Spec
  describe "Sanity" do
    it "should be sane" do
      true.must_equal true
      false.wont_equal true
    end
  end
end