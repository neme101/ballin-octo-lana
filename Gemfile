source "https://rubygems.org"

ruby "2.2.1"

gem "cuba", "~> 3.1"
gem "rack-protection", "~> 1.5"

gem "rake", "~> 10.1"
gem "dotenv", "~> 0.10"
gem "puma", "~> 2.8"

group :development do
  gem "rerun"
  gem "foreman"
  gem "pry"

  # Nice error pages in development.
  gem "better_errors"
  gem "binding_of_caller"
end

group :test do
  gem "minitest"
  gem "rack-test"
  gem "mocoso"
end
