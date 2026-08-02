# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/multipart/form_data"
require "stringio"

describe Protocol::Multipart::FormData do
	let(:form_data) {subject.new}
	
	def serialize(form_data)
		output = StringIO.new
		form_data.call(output)
		return output.string
	end
	
	it "handles field names with quotes correctly" do
		form_data.add_field('field"with"quotes', "test value")
		
		# Get the first part
		part = form_data.parts.first
		
		# Check that the Content-Disposition header properly escapes quotes
		expected_header = 'form-data; name="field\"with\"quotes"'
		expect(part.headers["content-disposition"]).to be == expected_header
	end
	
	it "handles field names with backslashes correctly" do
		form_data.add_field('field\\with\\backslashes', "test value")
		
		# Get the first part
		part = form_data.parts.first
		
		# Check that the Content-Disposition header properly escapes backslashes
		expected_header = 'form-data; name="field\\\\with\\\\backslashes"'
		expect(part.headers["content-disposition"]).to be == expected_header
	end
	
	it "handles field names with both quotes and backslashes" do
		form_data.add_field('field"with\\mixed"chars', "test value")
		
		# Get the first part
		part = form_data.parts.first
		
		# Check that both quotes and backslashes are properly escaped
		expected_header = 'form-data; name="field\"with\\\\mixed\"chars"'
		expect(part.headers["content-disposition"]).to be == expected_header
	end
	
	it "handles normal field names without changes" do
		form_data.add_field("normal_field_name", "test value")
		
		# Get the first part
		part = form_data.parts.first
		
		# Check that normal names are unchanged
		expected_header = 'form-data; name="normal_field_name"'
		expect(part.headers["content-disposition"]).to be == expected_header
	end
	
	it "handles empty form data without writing anything" do
		# Create a StringIO to capture what would be written
		output = StringIO.new
		
		# Call the form_data with no parts added - this should trigger the early return
		form_data.call(output)
		
		# Should write nothing since there are no parts
		expect(output.string).to be == ""
	end
	
	it "parses fields and streams uploads" do
		form_data.add_field("name", "Samuel")
		form_data.parts << Protocol::Multipart::StringPart.new(
			{
				"content-disposition" => 'form-data; name="avatar"; filename="samuel.txt"',
				"content-type" => "text/plain",
			},
			"Hello!"
		)
		
		values = {}
		result = subject.parse(StringIO.new(serialize(form_data)), form_data.boundary) do |name, value|
			if value.is_a?(subject::Upload)
				content = value.each.to_a.join
				expect(value.filename).to be == "samuel.txt"
				expect(value.headers["content-type"].type).to be == "text/plain"
				expect(value.size).to be == 6
				expect(value).to be(:ended?)
				values[name] = content
			else
				values[name] = value
			end
		end
		
		expect(result).to be == true
		expect(values).to be == {"name" => "Samuel", "avatar" => "Hello!"}
	end
	
	it "returns an enumerator without a block" do
		form_data.add_field("name", "Samuel")
		enumerator = subject.parse(StringIO.new(serialize(form_data)), form_data.boundary)
		
		expect(enumerator).to be_a(Enumerator)
		expect(enumerator.to_a).to be == [["name", "Samuel"]]
	end
	
	it "discards unread upload content through the limited stream" do
		form_data.parts << Protocol::Multipart::StringPart.new(
			{"content-disposition" => 'form-data; name="file"; filename="large.bin"'},
			"content"
		)
		
		upload = nil
		subject.parse(StringIO.new(serialize(form_data)), form_data.boundary) do |_name, value|
			upload = value
		end
		
		expect(upload.size).to be == 7
		expect(upload).to be(:ended?)
	end
	
	it "limits buffered field size" do
		form_data.add_field("field", "content")
		
		expect do
			subject.parse(StringIO.new(serialize(form_data)), form_data.boundary, maximum_field_size: 3).to_a
		end.to raise_exception(RangeError, message: be =~ /field_size exceeded/)
	end
	
	it "limits upload size even when the upload is not read by the consumer" do
		form_data.parts << Protocol::Multipart::StringPart.new(
			{"content-disposition" => 'form-data; name="file"; filename="large.bin"'},
			"content"
		)
		
		expect do
			subject.parse(StringIO.new(serialize(form_data)), form_data.boundary, maximum_upload_size: 3).to_a
		end.to raise_exception(RangeError, message: be =~ /upload_size exceeded/)
	end
	
	it "limits total field and upload content" do
		form_data.add_field("first", "one")
		form_data.add_field("second", "two")
		
		expect do
			subject.parse(StringIO.new(serialize(form_data)), form_data.boundary, maximum_total_size: 5).to_a
		end.to raise_exception(RangeError, message: be =~ /total_size exceeded/)
	end
	
	it "allows content limits to be disabled" do
		form_data.add_field("field", "content")
		
		values = subject.parse(
			StringIO.new(serialize(form_data)),
			form_data.boundary,
			maximum_field_size: nil,
			maximum_upload_size: nil,
			maximum_total_size: nil,
		).to_a
		
		expect(values).to be == [["field", "content"]]
	end
	
	it "rejects negative content limits" do
		expect do
			subject.parse(StringIO.new, "boundary", maximum_total_size: -1).to_a
		end.to raise_exception(ArgumentError, message: be =~ /must be non-negative/)
	end
	
	with "invalid form metadata" do
		def parse_part(header)
			boundary = "boundary"
			data = "--#{boundary}\r\n#{header}\r\n\r\nvalue\r\n--#{boundary}--\r\n"
			return Protocol::Multipart::FormData.parse(StringIO.new(data), boundary).to_a
		end
		
		it "rejects a missing content disposition" do
			expect{parse_part("Content-Type: text/plain")}.to raise_exception(ArgumentError, message: be =~ /missing a form-data name/)
		end
		
		it "rejects a non-form-data disposition" do
			expect{parse_part("Content-Disposition: attachment; name=field")}.to raise_exception(ArgumentError, message: be =~ /missing a form-data name/)
		end
		
		it "rejects a missing form field name" do
			expect{parse_part("Content-Disposition: form-data")}.to raise_exception(ArgumentError, message: be =~ /missing a form-data name/)
		end
	end
end
