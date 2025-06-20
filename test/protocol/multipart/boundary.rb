# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/multipart/boundary"

describe Protocol::Multipart do
	it "generates secure boundary without prefix" do
		boundary = Protocol::Multipart.secure_boundary
		
		expect(boundary).to be_a(String)
		expect(boundary.length).to be > 20
	end
	
	it "generates secure boundary with prefix" do
		boundary = Protocol::Multipart.secure_boundary("MyPrefix")
		
		expect(boundary).to be(:start_with?, "MyPrefix-")
		expect(boundary.length).to be > 30  # MyPrefix- + base64 content
	end
	
	it "generates secure boundary with custom length" do
		boundary = Protocol::Multipart.secure_boundary(nil, 16)
		
		# Base64 encoding of 16 bytes should be around 22 characters
		expect(boundary.length).to be >= 20
		expect(boundary.length).to be <= 25
	end
	
	it "generates secure boundary with both prefix and custom length" do
		boundary = Protocol::Multipart.secure_boundary("Test", 8)
		
		expect(boundary).to be(:start_with?, "Test-")
		# Test- (5 chars) + base64 of 8 bytes (~11 chars) = ~16 chars
		expect(boundary.length).to be >= 15
		expect(boundary.length).to be <= 20
	end
end
