Gem::Specification.new do |s|
  s.name        = 'activerecord-mti'
  s.version     = '0.0.0'
  s.date        = '2014-06-25'
  s.summary     = 'ActiveRecord MTI'
  s.description = 'Multiple Tables Inheritance for ActiveRecord'
  s.authors     = ['Timofey Martynov']
  s.email       = 'feymartynov@gmail.com'
  s.homepage    = 'http://rubygems.org/gems/activerecord-mti'
  s.license     = 'MIT'

  s.require_paths = ['lib']
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")

  s.add_dependency 'rails', '>= 3.2'
  s.add_development_dependency 'rspec-rails', '~> 2.14.0'
end
