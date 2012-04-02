require 'test_helper'

describe ActiveXen::Base do
  describe "Persistence" do
    before do
      require_xenserver
      @pool = ActiveXen::ConnectionPool.new
      @connection = @pool.connection("xenserver")

      @connection.connection.must_be_instance_of XenApi::Client
      @connection.api_version.must_match /^1.\d+/

      pool_ref = @connection.connection.pool.get_all()[0]
      host_ref = @connection.connection.pool.get_master(pool_ref)
      @host = ActiveXen::Models::Host.on(@connection).new(host_ref)

      @vm = ActiveXen::Models::VM.on(@connection).new(
        :actions_after_crash => 'restart',
        :actions_after_reboot => 'restart',
        :actions_after_shutdown => 'destroy',
        :user_version => 1,
        :is_a_template => false,
        :affinity => @host,

        :memory_static_min => 512.megabytes.to_s,
        :memory_static_max => 512.megabytes.to_s,
        :memory_dynamic_min => 512.megabytes.to_s,
        :memory_dynamic_max => 512.megabytes.to_s,

        :VCPUs_max => 2,
        :VCPUs_at_startup => 2,

        :PV_bootloader => "pygrub"
      )
    end

    after do
      @vm.destroy unless @vm.nil? || @vm.destroyed?
    end

    it "does actually persist" do
      @vm.uuid.must_be_nil
      @vm.ref.must_be_nil

      @vm.name_label = "Example VM that actually persists"
      @vm.must_be :valid?
      @vm.save!

      @vm.uuid.wont_be_nil
      @vm.ref.wont_be_nil

      uuid = @vm.uuid
      @vm.reload
      uuid.must_equal @vm.uuid

      persisted = ActiveXen::Models::VM.on(@connection).find_by_uuid(@vm.uuid)
      persisted.name_label.must_equal @vm.name_label
    end

    it "persists Booleans" do
      @vm.is_a_template.must_equal false

      @vm.must_be :valid?
      @vm.save!
      @vm.reload

      @vm.is_a_template.must_equal false
    end

    it "persists Numerics" do
      @vm.VCPUs_max.must_equal 2

      @vm.must_be :valid?
      @vm.save!
      @vm.reload

      @vm.VCPUs_max.must_equal 2
    end
  end
end