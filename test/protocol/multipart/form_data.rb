# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/multipart/form_data"
require "stringio"

describe Protocol::Multipart::FormData do
	let(:form_data) {subject.new}
	
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
end
