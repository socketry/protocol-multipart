# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/multipart/parser"
require "stringio"

describe Protocol::Multipart::Parser do
	let(:boundary) {"ProtocolMultipartBoundary"}
	
	it "parses multipart data correctly" do
		data = "--#{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"example.txt\"\r\n\r\nHello World\r\n--#{boundary}--\r\n"
		readable = StringIO.new(data)
		parser = Protocol::Multipart::Parser.new(readable, boundary)
		
		parts_data = []
		parser.each do |part|
			expect(part.headers).to be_a(Protocol::Multipart::Headers)
			expect(part.headers["content-disposition"].type).to be == "form-data"
			expect(part.headers["content-disposition"]["filename"]).to be == "example.txt"
			content = String.new
			part.each{|chunk| content << chunk}
			parts_data << content
		end
		
		expect(parts_data.size).to be == 1
		expect(parts_data.first).to be(:include?, "Hello World")
	end
	
	it "handles multiple parts" do
		data = "--#{boundary}\r\nContent-Disposition: form-data; name=\"field1\"\r\n\r\nvalue1\r\n--#{boundary}\r\nContent-Disposition: form-data; name=\"field2\"\r\n\r\nvalue2\r\n--#{boundary}--\r\n"
		readable = StringIO.new(data)
		parser = Protocol::Multipart::Parser.new(readable, boundary)
		
		parts_data = []
		parser.each do |part|
			# Store both headers and content for each part
			part_content = String.new
			part.each{|chunk| part_content << chunk}
			parts_data << {headers: part.headers, content: part_content}
		end
		
		expect(parts_data).to have_attributes(size: be == 2)
		
		first_part = parts_data.first
		expect(first_part[:headers]["content-disposition"]["name"]).to be == "field1"
		expect(first_part[:content]).to be(:include?, "value1")
		
		second_part = parts_data.last
		expect(second_part[:headers]["content-disposition"]["name"]).to be == "field2"
		expect(second_part[:content]).to be(:include?, "value2")
	end
	
	it "limits the preamble size" do
		data = "preamble\r\n--#{boundary}\r\n\r\n--#{boundary}--\r\n"
		parser = Protocol::Multipart::Parser.new(StringIO.new(data), boundary, maximum_preamble_size: 4)
		
		expect{parser.each.to_a}.to raise_exception(RangeError, message: be =~ /preamble_size exceeded/)
	end
	
	it "limits an unterminated preamble" do
		parser = Protocol::Multipart::Parser.new(StringIO.new("x" * 1024), boundary, maximum_preamble_size: 16)
		
		expect{parser.each.to_a}.to raise_exception(RangeError, message: be =~ /preamble_size exceeded/)
	end
	
	it "allows a boundary after the maximum preamble size" do
		data = "x\r\n--#{boundary}\r\n\r\n--#{boundary}--\r\n"
		parser = Protocol::Multipart::Parser.new(StringIO.new(data), boundary, maximum_preamble_size: 3)
		
		expect(parser.each.to_a).to be(:empty?)
	end
	
	it "limits each part's header size" do
		data = "--#{boundary}\r\nContent-Type: text/plain\r\n\r\nvalue\r\n--#{boundary}--\r\n"
		parser = Protocol::Multipart::Parser.new(StringIO.new(data), boundary, maximum_header_size: 16)
		
		expect{parser.each.to_a}.to raise_exception(RangeError, message: be =~ /header_size exceeded/)
	end
	
	it "limits an unterminated header" do
		data = "--#{boundary}\r\nX-Test: #{'x' * 1024}"
		parser = Protocol::Multipart::Parser.new(StringIO.new(data), boundary, maximum_header_size: 16)
		
		expect{parser.each.to_a}.to raise_exception(RangeError, message: be =~ /header_size exceeded/)
	end
	
	it "allows the header terminator after the maximum header size" do
		data = "--#{boundary}\r\nX: y\r\n\r\nvalue\r\n--#{boundary}--\r\n"
		parser = Protocol::Multipart::Parser.new(StringIO.new(data), boundary, maximum_header_size: 6)
		
		expect(parser.each.to_a.size).to be == 1
	end
	
	it "limits each part's header count" do
		data = "--#{boundary}\r\nContent-Type: text/plain\r\nX-Test: true\r\n\r\nvalue\r\n--#{boundary}--\r\n"
		parser = Protocol::Multipart::Parser.new(StringIO.new(data), boundary, maximum_header_count: 1)
		
		expect{parser.each.to_a}.to raise_exception(RangeError, message: be =~ /header_count exceeded/)
	end
	
	it "limits the part count" do
		data = "--#{boundary}\r\n\r\none\r\n--#{boundary}\r\n\r\ntwo\r\n--#{boundary}--\r\n"
		parser = Protocol::Multipart::Parser.new(StringIO.new(data), boundary, maximum_part_count: 1)
		
		expect{parser.each.to_a}.to raise_exception(RangeError, message: be =~ /part_count exceeded/)
	end
	
	it "allows limits to be disabled" do
		data = "preamble\r\n--#{boundary}\r\nContent-Type: text/plain\r\n\r\nvalue\r\n--#{boundary}--\r\n"
		parser = Protocol::Multipart::Parser.new(StringIO.new(data), boundary, maximum_preamble_size: nil, maximum_header_size: nil, maximum_header_count: nil, maximum_part_count: nil)
		
		expect(parser.each.to_a.size).to be == 1
	end
	
	it "rejects negative limits" do
		expect do
			Protocol::Multipart::Parser.new(StringIO.new, boundary, maximum_part_count: -1)
		end.to raise_exception(ArgumentError, message: be =~ /must be non-negative/)
	end
	
	it "skips empty parts" do
		data = "--#{boundary}\r\n\r\n--#{boundary}--\r\n"
		readable = StringIO.new(data)
		parser = Protocol::Multipart::Parser.new(readable, boundary)
		
		parts = parser.each.to_a
		expect(parts).to be(:empty?)
	end
	
	it "yields body data in chunks" do
		data = "--#{boundary}\r\nContent-Type: text/plain\r\n\r\n#{'x' * 1000}\r\n--#{boundary}--\r\n"
		readable = StringIO.new(data)
		parser = Protocol::Multipart::Parser.new(readable, boundary)
		
		chunks = []
		parser.each do |part|
			# Use a much smaller chunk size to ensure multiple chunks
			part.each(10){|chunk| chunks << chunk}
		end
		
		expect(chunks.length).to be > 1
		expect(chunks.join).to be(:include?, "x" * 1000)
	end
	
	it "discards part data without collecting it" do
		data = "--#{boundary}\r\nContent-Type: text/plain\r\n\r\nSome content to discard\r\n--#{boundary}--\r\n"
		readable = StringIO.new(data)
		parser = Protocol::Multipart::Parser.new(readable, boundary)
		
		parser.each do |part|
			# Explicitly discard the part
			part.discard
		end
		
		# No error means success
	end
	
	it "does not drain a part when the consumer raises" do
		data = "--#{boundary}\r\nContent-Type: text/plain\r\n\r\nSome content\r\n--#{boundary}--\r\n"
		parser = Protocol::Multipart::Parser.new(StringIO.new(data), boundary)
		part = nil
		
		expect do
			parser.each do |current|
				part = current
				raise "Stop parsing!"
			end
		end.to raise_exception(RuntimeError, message: be == "Stop parsing!")
		
		expect(part).not.to be(:ended?)
	end
	
	it "finishes part without collecting all data" do
		data = "--#{boundary}\r\nContent-Type: text/plain\r\n\r\nPartial read content\r\n--#{boundary}--\r\n"
		readable = StringIO.new(data)
		parser = Protocol::Multipart::Parser.new(readable, boundary)
		
		parser.each do |part|
			# Read just the first 5 bytes
			content = String.new
			part.each(5) do |chunk|
				content << chunk
				break # Only read one chunk
			end
			
			expect(content.size).to be <= 5
			
			# Finish should read the rest without yielding
			remaining = part.finish
			expect(remaining).not.to be(:nil?)
		end
	end
	
	it "correctly handles closing boundary" do
		data = "--#{boundary}\r\nContent-Type: text/plain\r\n\r\nTest content\r\n--#{boundary}--\r\n"
		readable = StringIO.new(data)
		parser = Protocol::Multipart::Parser.new(readable, boundary)
		
		content = String.new
		parser.each do |part|
			expect(part.headers["content-type"].type).to be == "text/plain"
			part.each{|chunk| content << chunk}
		end
		
		expect(content).to be == "Test content"
	end
	
	it "checks if part has ended" do
		data = "--#{boundary}\r\nContent-Type: text/plain\r\n\r\nTest content\r\n--#{boundary}--\r\n"
		readable = StringIO.new(data)
		parser = Protocol::Multipart::Parser.new(readable, boundary)
		
		parser.each do |part|
			# Before reading, part shouldn't be ended
			expect(part.ended?).to be == false
			
			part.finish # Read the part completely
			
			# After reading, part should be ended
			expect(part.ended?).to be == true
		end
	end
	
	it "rejects duplicate content type headers" do
		data = "--#{boundary}\r\nContent-Type: text/plain\r\nContent-Type: text/html\r\n\r\nTest content\r\n--#{boundary}--\r\n"
		readable = StringIO.new(data)
		parser = Protocol::Multipart::Parser.new(readable, boundary)
		
		expect do
			parser.each.first.headers["content-type"]
		end.to raise_exception(Protocol::HTTP::DuplicateHeaderError)
	end
	
	it "rejects triple duplicate content type headers" do
		data = <<~MULTIPART
			--#{boundary}\r
			Content-Type: text/plain\r
			Content-Type: text/html\r
			Content-Type: application/json\r
			\r
			Test content\r
			--#{boundary}--\r
		MULTIPART
		
		readable = StringIO.new(data)
		parser = Protocol::Multipart::Parser.new(readable, boundary)
		
		expect do
			parser.each.first.headers["content-type"]
		end.to raise_exception(Protocol::HTTP::DuplicateHeaderError)
	end
	
	it "handles unexpected end of stream during part reading" do
		# Create truncated multipart data that ends unexpectedly
		data = <<~MULTIPART
			--#{boundary}\r
			Content-Type: text/plain\r
			\r
			Partial content that gets cut off
		MULTIPART
		
		readable = StringIO.new(data)
		parser = Protocol::Multipart::Parser.new(readable, boundary)
		
		expect do
			parser.each do |part|
				part.each{|chunk|} # Try to read all content
			end
		end.to raise_exception(EOFError)
	end
	
	it "handles unexpected end of stream during part finishing" do
		# Create truncated multipart data for finish method
		data = <<~MULTIPART
			--#{boundary}\r
			Content-Type: text/plain\r
			\r
			Content that will be finished but truncated
		MULTIPART
		
		readable = StringIO.new(data)
		parser = Protocol::Multipart::Parser.new(readable, boundary)
		
		expect do
			parser.each do |part|
				part.finish # Try to finish reading the part
			end
		end.to raise_exception(EOFError)
	end
	
	it "handles unexpected end of stream during part discarding" do
		# Create truncated multipart data for discard method
		data = <<~MULTIPART
			--#{boundary}\r
			Content-Type: text/plain\r
			\r
			Content that will be discarded but truncated
		MULTIPART
		
		readable = StringIO.new(data)
		parser = Protocol::Multipart::Parser.new(readable, boundary)
		
		expect do
			parser.each do |part|
				part.discard # Try to discard the part
			end
		end.to raise_exception(EOFError)
	end
	
	it "handles stream end without finding boundary" do
		# Create data that has headers but no boundary - this should be caught in the error handling
		data = <<~MULTIPART
			--#{boundary}\r
			Content-Type: text/plain\r
			\r
			Content without proper boundary ending
		MULTIPART
		
		readable = StringIO.new(data)
		parser = Protocol::Multipart::Parser.new(readable, boundary)
		
		# This should raise an error due to stream ending without proper boundary
		expect do
			parser.each do |part|
				part.each{|chunk|} # Try to read content - should hit EOF
			end
		end.to raise_exception(EOFError)
	end
	
	it "raises error when no boundary is found in stream" do
		# Data with no boundary at all
		data = "Some random content without any boundaries\r\nMore content\r\n"
		
		readable = StringIO.new(data)
		parser = Protocol::Multipart::Parser.new(readable, boundary)
		
		# The parser should raise an error when no boundary is found
		expect do
			parser.each.to_a
		end.to raise_exception(EOFError, message: be =~ /No multipart boundary found in stream/)
	end
	
	describe "part headers" do
		it "preserves repeated extension headers" do
			data = <<~MULTIPART
				--#{boundary}\r
				X-Custom: first\r
				X-Custom: second\r
				\r
				Test content\r
				--#{boundary}--\r
			MULTIPART
			
			readable = StringIO.new(data)
			parser = Protocol::Multipart::Parser.new(readable, boundary)
			
			expect(parser.each.first.headers["x-custom"]).to be == ["first", "second"]
		end
		
		it "rejects folded headers" do
			data = <<~MULTIPART
				--#{boundary}\r
				Content-Type: text/plain;\r
				 charset=utf-8\r
				\r
				Test content\r
				--#{boundary}--\r
			MULTIPART
			
			readable = StringIO.new(data)
			parser = Protocol::Multipart::Parser.new(readable, boundary)
			
			expect do
				parser.each.first
			end.to raise_exception(RuntimeError, message: be =~ /Invalid header line/)
		end
		
		it "rejects whitespace before the colon" do
			data = <<~MULTIPART
				--#{boundary}\r
				Content-Type : text/plain\r
				\r
				Test content\r
				--#{boundary}--\r
			MULTIPART
			
			readable = StringIO.new(data)
			parser = Protocol::Multipart::Parser.new(readable, boundary)
			
			expect do
				parser.each.first
			end.to raise_exception(RuntimeError, message: be =~ /Invalid header line/)
		end
		
		it "rejects control characters in header values" do
			data = "--#{boundary}\r\nX-Custom: first\0second\r\n\r\nTest content\r\n--#{boundary}--\r\n"
			readable = StringIO.new(data)
			parser = Protocol::Multipart::Parser.new(readable, boundary)
			
			expect do
				parser.each.first
			end.to raise_exception(RuntimeError, message: be =~ /Invalid header line/)
		end
		
		it "handles normal headers without folding" do
			data = <<~MULTIPART
				--#{boundary}\r
				Content-Type: text/plain\r
				Content-Length: 12\r
				\r
				Test content\r
				--#{boundary}--\r
			MULTIPART
			
			readable = StringIO.new(data)
			parser = Protocol::Multipart::Parser.new(readable, boundary)
			
			part = parser.each.first
			expect(part.headers["content-type"].type).to be == "text/plain"
			expect(part.headers["content-length"]).to be == "12"
		end
	end
	
	describe "error handling" do
		it "raises EOFError when stream ends unexpectedly while reading boundary suffix" do
			# Create malformed data where boundary is found but suffix is missing
			data = <<~MULTIPART.chomp
				--#{boundary}\r
				Content-Type: text/plain\r
				\r
				Some content\r
				--#{boundary}
			MULTIPART
			
			readable = StringIO.new(data)
			parser = Protocol::Multipart::Parser.new(readable, boundary)
			
			expect do
				parser.each do |part|
					part.each{|chunk|}
				end
			end.to raise_exception(EOFError, message: be =~ /Unexpected end of stream while reading part data/)
		end
		
		it "raises error on invalid header line format" do
			data = <<~MULTIPART
				--#{boundary}\r
				Content-Type: text/plain\r
				Invalid Header Line Without Colon\r
				\r
				Content\r
				--#{boundary}--\r
			MULTIPART
			
			readable = StringIO.new(data)
			parser = Protocol::Multipart::Parser.new(readable, boundary)
			
			expect do
				parser.each.first
			end.to raise_exception(RuntimeError, message: be =~ /Invalid header line/)
		end
		
		it "raises error when stream ends unexpectedly while reading headers" do
			# Create data that has a boundary but no empty line to terminate headers
			data = "--#{boundary}\r\nContent-Type: text/plain\r\n"
			
			readable = StringIO.new(data)
			parser = Protocol::Multipart::Parser.new(readable, boundary)
			
			expect do
				parser.each.first
			end.to raise_exception(EOFError, message: be =~ /Unexpected end of stream while reading headers/)
		end
	end
	
	it "handles non-closing boundary with just CRLF suffix" do
		# Create multipart data with two parts - first ending with regular boundary, not closing boundary
		data = "--#{boundary}\r\nContent-Type: text/plain\r\n\r\nFirst part content\r\n--#{boundary}\r\nContent-Type: text/plain\r\n\r\nSecond part content\r\n--#{boundary}--\r\n"
		
		readable = StringIO.new(data)
		parser = Protocol::Multipart::Parser.new(readable, boundary)
		
		parts = []
		
		# Get the first part and discard it (should hit the boundary suffix == "\r\n" branch)
		parser.each do |part|
			part.discard
			parts << part
		end
		
		# Should have processed both parts
		expect(parts.size).to be == 2
		
		# First part should not have a closing boundary
		expect(parts.first.closing_boundary?).to be == false
		
		# Second part should have a closing boundary
		expect(parts.last.closing_boundary?).to be == true
	end
end
