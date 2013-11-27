source 'https://rubygems.org'

group :development do
  gem 'guard-rspec'
  gem 'terminal-notifier-guard' if /darwin/ =~ RUBY_PLATFORM
end

group :test, :development do
  gem 'rake'
  gem 'rspec'
  gem 'webmock'
end

gem 'rubysl', platforms: :rbx

# Specify your gem's dependencies in baidu-pcs.gemspec
gemspec
