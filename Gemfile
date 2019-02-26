source 'https://rubygems.org'
gemspec

# Use .ruby-version file as canonical Ruby version
ruby File.read(File.join(File.dirname(__FILE__), '.ruby-version')).chomp

# We don't include as a development dependency in the gemspec as RuboCop is not
# a development dependency but a CI one, so we don't want to constrain projects
# that include geoengineer in their gemfile to use the same version of RuboCop
# we use for development.
gem 'rubocop', '0.51.0'
