# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/multipart/mixed"
require "protocol/multipart/string_part"
require "stringio"

describe Protocol::Multipart::Mixed do
	let(:mixed) {subject.new({}, [], boundary: "TestBoundary123")}
	
	it "returns early when parts are empty" do
		output = StringIO.new
		
		# This should trigger the early return on line 37: return if @parts.empty?
		mixed.call(output)
		
		# Should produce no output since there are no parts
		expect(output.string).to be == ""
	end
	
	it "writes multipart content with parts" do
		# Add a part
		part = Protocol::Multipart::StringPart.new({"content-type" => "text/plain"}, "Hello World")
		mixed.parts << part
		
		output = StringIO.new
		mixed.call(output)
		
		expect(output.string).to be == <<~MULTIPART
			--TestBoundary123\r
			content-type: text/plain\r
			\r
			Hello World\r
			--TestBoundary123--\r
		MULTIPART
	end
	
	it "writes middle boundaries between multiple parts" do
		# Add multiple parts to trigger the middle boundary logic (line 51)
		part1 = Protocol::Multipart::StringPart.new({"content-type" => "text/plain"}, "First part")
		part2 = Protocol::Multipart::StringPart.new({"content-type" => "text/html"}, "Second part")
		
		mixed.parts << part1
		mixed.parts << part2
		
		output = StringIO.new
		mixed.call(output)
		
		expect(output.string).to be == <<~MULTIPART
			--TestBoundary123\r
			content-type: text/plain\r
			\r
			First part\r
			--TestBoundary123\r
			content-type: text/html\r
			\r
			Second part\r
			--TestBoundary123--\r
		MULTIPART
	end
end
