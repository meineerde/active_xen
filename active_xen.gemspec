# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "active_xen/version"

Gem::Specification.new do |s|
  s.name        = "active_xen"
  s.version     = ActiveXen::VERSION
  s.authors     = ["Holger Just"]
  s.email       = ["hjust@meine-er.de"]
  s.homepage    = ""
  s.summary     = %q{An ActiveModel compliant wrapper for the Citrix XenServer API}
  s.description = %q{An ActiveModel compliant wrapper for the Citrix XenServer API}

  s.rubyforge_project = "active_xen"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'activesupport', '~> 3.2.0'
  s.add_runtime_dependency 'activemodel', '~> 3.2.0'
  s.add_runtime_dependency 'xenapi'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'bundler', '>= 1.0.0'
  s.add_development_dependency 'minitest', '~> 2.10.0'
  s.add_development_dependency 'mocha', '~> 0.10.3'
  s.add_development_dependency 'minitest-matchers', '~> 1.1.3'
  s.add_development_dependency 'valid_attribute', '~> 1.2.0'
end
