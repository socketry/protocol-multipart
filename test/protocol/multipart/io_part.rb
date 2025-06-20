# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/multipart/io_part"
require "stringio"
require "tempfile"

describe Protocol::Multipart::IOPart do
	let(:temp_file) do
		file = Tempfile.new("test")
		file.write("Hello World from file")
		file.rewind
		file
	end
	
	after do
		temp_file.close
		temp_file.unlink
	end
	
	it "opens a file with default headers" do
		io_part = Protocol::Multipart::IOPart.open(temp_file.path)
		
		expect(io_part.headers["content-disposition"]).to be(:start_with?, 'attachment; filename="')
		expect(io_part.headers["content-type"]).to be == "application/octet-stream"
		expect(io_part.io).to be_a(File)
	end
	
	it "opens a file with custom mime type and name" do
		io_part = Protocol::Multipart::IOPart.open(
			temp_file.path, 
			mime_type: "text/plain", 
			name: "custom.txt"
		)
		
		expect(io_part.headers["content-disposition"]).to be == 'attachment; filename="custom.txt"'
		expect(io_part.headers["content-type"]).to be == "text/plain"
	end
	
	it "opens a file with additional headers" do
		io_part = Protocol::Multipart::IOPart.open(
			temp_file.path,
			headers: {"x-custom-header" => "custom-value"}
		)
		
		expect(io_part.headers["x-custom-header"]).to be == "custom-value"
		expect(io_part.headers["content-disposition"]).to be(:start_with?, 'attachment; filename="')
	end
	
	it "initializes with headers and io" do
		io = StringIO.new("test content")
		headers = {"content-type" => "text/plain"}
		
		io_part = Protocol::Multipart::IOPart.new(headers, io)
		
		expect(io_part.headers).to be == headers
		expect(io_part.io).to be == io
	end
	
	it "writes io content to writable" do
		io = StringIO.new("Hello World")
		io_part = Protocol::Multipart::IOPart.new({}, io)
		output = StringIO.new
		
		io_part.call(output, "boundary")
		
		expect(output.string).to be == "Hello World"
	end
	
	it "writes large io content in chunks" do
		# Create content larger than the 8192 byte chunk size
		large_content = "x" * 10000
		io = StringIO.new(large_content)
		io_part = Protocol::Multipart::IOPart.new({}, io)
		output = StringIO.new
		
		io_part.call(output, "boundary")
		
		expect(output.string).to be == large_content
	end
end
