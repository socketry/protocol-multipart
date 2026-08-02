# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/multipart/header"

describe Protocol::Multipart::Header do
	it "parses a content type with a quoted boundary" do
		header = subject.parse('Multipart/Form-Data; boundary="boundary;with:semicolon"')
		
		expect(header.type).to be == "multipart/form-data"
		expect(header["boundary"]).to be == "boundary;with:semicolon"
	end
	
	it "parses a form data disposition" do
		header = subject.parse('form-data; name="upload"; filename="a\"b.txt"')
		
		expect(header.type).to be == "form-data"
		expect(header.parameters).to be == {
			"name" => "upload",
			"filename" => 'a"b.txt'
		}
	end
	
	it "parses token parameters" do
		header = subject.parse("text/plain; charset=UTF-8")
		
		expect(header["CHARSET"]).to be == "UTF-8"
	end
	
	it "rejects malformed parameters" do
		expect{subject.parse("text/plain; charset")}.to raise_exception(ArgumentError, message: be =~ /Invalid header parameter/)
	end
	
	it "rejects malformed primary values" do
		expect{subject.parse("text/plain/invalid")}.to raise_exception(ArgumentError, message: be =~ /Invalid header parameter/)
	end
	
	it "rejects unterminated quoted parameters" do
		expect{subject.parse('form-data; name="field')}.to raise_exception(ArgumentError, message: be =~ /Invalid header parameter/)
	end
	
	it "rejects duplicate parameters" do
		expect{subject.parse("text/plain; charset=utf-8; charset=ascii")}.to raise_exception(ArgumentError, message: be =~ /Duplicate header parameter/)
	end
end
