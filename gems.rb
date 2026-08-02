# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

source "https://rubygems.org"

gemspec

group :maintenance, optional: true do
	gem "bake-modernize"
	gem "bake-gem"
	
	gem "utopia-project", "~> 0.18"
	gem "bake-releases"
	gem "decode"
end

group :test do
	gem "covered"
	gem "sus"
	gem "rubocop"
	gem "rubocop-md"
	gem "rubocop-socketry"
	
	gem "sus-fixtures-async"
	
	gem "bake-test"
	gem "bake-test-external"
end
