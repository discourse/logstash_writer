# frozen_string_literal: true

require 'bundler'
Bundler.setup(:default, :development)
require 'rspec/core'
require 'rspec/mocks'

require 'simplecov'
SimpleCov.start do
  add_filter('spec')
end

if Thread.respond_to?(:report_on_exception)
  Thread.report_on_exception = false
end

RSpec.configure do |config|
  config.order = :random
  config.fail_fast = true
  #config.full_backtrace = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require_relative './example_methods'

RSpec.configure do |config|
  config.include ExampleMethods
end
