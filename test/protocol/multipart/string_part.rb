# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/multipart/string_part"
require "stringio"

describe Protocol::Multipart::StringPart do
	let(:headers) { {"content-type" => "text/plain"} }
	let(:content) { "Hello, World!" }
	let(:part) { Protocol::Multipart::StringPart.new(headers, content) }
	
	it "initializes with headers and content" do
		expect(part.headers).to be == headers
		expect(part.content).to be == content
	end
	
	it "writes content to writable stream" do
		output = StringIO.new
		boundary = "test-boundary"
		
		# This covers line 17: writable.write(@content)
		part.call(output, boundary)
		
		expect(output.string).to be == content
	end
	
	it "handles empty content" do
		empty_part = Protocol::Multipart::StringPart.new(headers, "")
		output = StringIO.new
		
		empty_part.call(output, "boundary")
		
		expect(output.string).to be == ""
	end
	
	it "handles large content" do
		large_content = "x" * 10000
		large_part = Protocol::Multipart::StringPart.new(headers, large_content)
		output = StringIO.new
		
		large_part.call(output, "boundary")
		
		expect(output.string).to be == large_content
	end
end
