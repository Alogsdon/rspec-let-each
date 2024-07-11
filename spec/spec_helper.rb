Dir['./spec/support/**/*.rb'].map do |file|
  require file.gsub('./spec/support', 'support')
end

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
end
