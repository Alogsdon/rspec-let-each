
if defined?(RSpec)
  require 'let_each/version'
  require 'let_each/extension'
  RSpec.configure do |config|
    config.extend LetEach::Extension
  end
end
