# encoding: utf-8

Gem::Specification.new do |gem|
  gem.name = 'omnicontacts'
  gem.description = %q{A generalized Rack framework for importing contacts from major email providers.}
  gem.authors = ['Diego Castorina']
  gem.email = ['diegocastorina@gmail.com']

  gem.add_runtime_dependency 'rack'

  gem.version = "0.0.1"
  #gem.files = `git ls-files`.split("\n")
  #gem.homepage = 'http://github.com/intridea/omniauth'
  #gem.require_paths = ['lib']
  #gem.required_rubygems_version = Gem::Requirement.new('>= 1.3.6') if gem.respond_to? :required_rubygems_version=
  #gem.summary = gem.description
  #gem.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
end
