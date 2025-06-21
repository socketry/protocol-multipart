# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/multipart"

describe Protocol::Multipart do
	it "has a version number" do
		expect(Protocol::Multipart::VERSION).to be =~ /^\d+\.\d+\.\d+$/
	end
	
	it "has a parser" do
		expect(Protocol::Multipart::Parser).to be_a(Class)
	end
	
	it "has a mixed part class" do
		expect(Protocol::Multipart::Mixed).to be_a(Class)
	end
	
	it "has a part class" do
		expect(Protocol::Multipart::Part).to be_a(Class)
	end
end