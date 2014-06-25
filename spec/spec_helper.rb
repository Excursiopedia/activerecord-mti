require 'rails/all'
require 'rspec/rails'
require 'activerecord-mti'

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true
  config.formatter = :documentation
end
