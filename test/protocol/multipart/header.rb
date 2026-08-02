# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/multipart/headers"

describe Protocol::Multipart::Header::Parameterized do
	it "parses a content type with a quoted boundary" do
		headers = Protocol::Multipart::Headers.new([["Content-Type", 'Multipart/Form-Data; boundary="boundary;with:semicolon"']])
		header = headers["content-type"]
		
		expect(header).to be_a(Protocol::Multipart::Header::ContentType)
		expect(header.type).to be == "multipart/form-data"
		expect(header["boundary"]).to be == "boundary;with:semicolon"
	end
	
	it "parses a form data disposition" do
		headers = Protocol::Multipart::Headers.new([["Content-Disposition", 'form-data; name="upload"; filename="a\"b.txt"']])
		header = headers["content-disposition"]
		
		expect(header).to be_a(Protocol::Multipart::Header::ContentDisposition)
		expect(header.type).to be == "form-data"
		expect(header.parameters).to be == {
			"name" => "upload",
			"filename" => 'a"b.txt'
		}
	end
	
	it "parses token parameters" do
		header = Protocol::Multipart::Header::ContentType.parse("text/plain; charset=UTF-8")
		
		expect(header["CHARSET"]).to be == "UTF-8"
	end
	
	it "parses non-ASCII quoted parameters" do
		filename = "caf\u00e9.txt"
		header = Protocol::Multipart::Header::ContentDisposition.parse(%(form-data; filename="#{filename}"))
		
		expect(header["filename"]).to be == filename
	end
	
	it "parses escape-heavy quoted parameters" do
		quoted = 'a\\"' * 4096
		header = Protocol::Multipart::Header::ContentDisposition.parse(%(form-data; filename="#{quoted}"))
		
		expect(header["filename"]).to be == ('a"' * 4096)
	end
	
	it "rejects malformed parameters" do
		expect{Protocol::Multipart::Header::ContentType.parse("text/plain; charset")}.to raise_exception(ArgumentError, message: be =~ /Invalid header parameter/)
	end
	
	it "rejects malformed primary values" do
		expect{Protocol::Multipart::Header::ContentType.parse("text/plain/invalid")}.to raise_exception(ArgumentError, message: be =~ /Invalid header parameter/)
	end
	
	it "requires a content type and subtype" do
		expect{Protocol::Multipart::Header::ContentType.parse("text")}.to raise_exception(ArgumentError, message: be =~ /Invalid header value/)
	end
	
	it "requires a single content disposition token" do
		expect{Protocol::Multipart::Header::ContentDisposition.parse("form/data")}.to raise_exception(ArgumentError, message: be =~ /Invalid header parameter/)
	end
	
	it "rejects missing primary values" do
		expect{Protocol::Multipart::Header::ContentType.parse("")}.to raise_exception(ArgumentError, message: be =~ /Invalid header value/)
	end
	
	it "rejects unterminated quoted parameters" do
		expect{Protocol::Multipart::Header::ContentDisposition.parse('form-data; name="field')}.to raise_exception(ArgumentError, message: be =~ /Invalid header parameter/)
	end
	
	it "rejects folded parameters" do
		expect{Protocol::Multipart::Header::ContentDisposition.parse("form-data;\r\n name=field")}.to raise_exception(ArgumentError, message: be =~ /Invalid header parameter/)
	end
	
	it "rejects control characters in quoted parameters" do
		expect{Protocol::Multipart::Header::ContentDisposition.parse("form-data; name=\"field\0name\"")}.to raise_exception(ArgumentError, message: be =~ /Invalid header parameter/)
	end
	
	it "rejects duplicate parameters" do
		expect{Protocol::Multipart::Header::ContentType.parse("text/plain; charset=utf-8; charset=ascii")}.to raise_exception(ArgumentError, message: be =~ /Duplicate header parameter/)
	end
	
	it "rejects duplicate parameterized headers" do
		headers = Protocol::Multipart::Headers.new([
			["Content-Type", "text/plain"],
			["Content-Type", "text/html"],
		])
		
		expect{headers["content-type"]}.to raise_exception(Protocol::HTTP::DuplicateHeaderError)
	end
	
	it "serializes parameterized headers" do
		header = Protocol::Multipart::Header::ContentDisposition.new("form-data", {"name" => "upload", "filename" => 'a\\b"c.txt'})
		
		serialized = header.to_s
		expect(serialized).to be == 'form-data; name="upload"; filename="a\\\\b\"c.txt"'
		expect(Protocol::Multipart::Header::ContentDisposition.parse(serialized).parameters).to be == header.parameters
	end
	
	it "coerces assigned values using the policy" do
		headers = Protocol::Multipart::Headers.new
		headers["content-type"] = "text/plain; charset=utf-8"
		
		expect(headers["content-type"]).to be_a(Protocol::Multipart::Header::ContentType)
		expect(headers["content-type"]["charset"]).to be == "utf-8"
	end
	
	it "preserves a coerced parsed value" do
		header = Protocol::Multipart::Header::ContentType.parse("text/plain")
		
		expect(Protocol::Multipart::Header::ContentType.coerce(header)).to be_equal(header)
	end
end
