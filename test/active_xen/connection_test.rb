require 'test_helper'

describe ActiveXen::Connection do

  before do
    XenApi::Client.any_instance.stubs(:_do_call).with("session.login_with_password", ["root", "secure"]).returns("session")
    XenApi::Client.any_instance.stubs(:_do_call).with("session.logout", ["session"]).returns(nil)
    @hosts = ['https://example.com/', 'https://test.com/']
    ActiveXen::ConnectionPool.register('test', @hosts, "root", "secure")
    @pool = ActiveXen::ConnectionPool.new
  end

  it "generates a connection" do
    connection = @pool.connection('test')
    connection.must_be_instance_of ActiveXen::Connection
    connection.connection.must_be_instance_of XenApi::Client
  end

  it "re-uses existing connections" do
    connection1 = @pool.connection('test')
    connection2 = @pool.connection('test')

    connection1.must_equal connection2
  end

  it "clears active connection on clear" do
    connection1 = @pool.connection('test')
    @pool.clear.must_equal Hash.new
    connection2 = @pool.connection('test')

    connection1.wont_equal connection2
  end

  it "reconnects on errors" do
    XenApi::Client.any_instance.stubs(:_do_call).with("VM.get_uuid", ['session']).
      # two more errors because of the same-server retry
      raises(XenApi::Client::SessionInvalid).
      raises(XenApi::Client::SessionInvalid).
      raises(XenApi::Client::SessionInvalid).
      then.returns("abc123")

    connection = @pool.connection('test')

    connection.connection.uri.to_s.must_equal @hosts[0]
    connection.VM.get_uuid.must_equal "abc123"
    connection.connection.uri.to_s.must_equal @hosts[1]
  end

  it "connect to the master when trying to connect to a slave" do
    master = URI.parse(@hosts[1])

    XenApi::Client.any_instance.stubs(:_do_call).
      with("session.login_with_password", ["root", "secure"]).
      raises(XenApi::Errors::HostIsSlave.new([master.host])).then.
      returns("session")

    connection = @pool.connection('test')
    connection.connection.uri.must_equal master
  end
end
