# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/multipart/escape"

describe Protocol::Multipart::Escape do
	let(:test_class) do
		Class.new do
			include Protocol::Multipart::Escape
		end
	end
	
	let(:instance) {test_class.new}
	
	describe "#escape_field_name" do
		it "escapes quotes correctly" do
			result = instance.escape_field_name('field"with"quotes')
			expect(result).to be == 'field\"with\"quotes'
		end
		
		it "escapes backslashes correctly" do
			result = instance.escape_field_name('field\\with\\backslashes')
			expect(result).to be == 'field\\\\with\\\\backslashes'
		end
		
		it "escapes both quotes and backslashes" do
			result = instance.escape_field_name('field"with\\mixed"chars')
			expect(result).to be == 'field\"with\\\\mixed\"chars'
		end
		
		it "leaves normal field names unchanged" do
			result = instance.escape_field_name("normal_field_name")
			expect(result).to be == "normal_field_name"
		end
		
		it "handles empty strings" do
			result = instance.escape_field_name("")
			expect(result).to be == ""
		end
		
		it "converts non-string input to string" do
			result = instance.escape_field_name(123)
			expect(result).to be == "123"
		end
	end
	
	describe "#unescape_field_name" do
		it "unescapes quotes correctly" do
			result = instance.unescape_field_name('field\"with\"quotes')
			expect(result).to be == 'field"with"quotes'
		end
		
		it "unescapes backslashes correctly" do
			result = instance.unescape_field_name('field\\\\with\\\\backslashes')
			expect(result).to be == 'field\\with\\backslashes'
		end
		
		it "unescapes both quotes and backslashes" do
			result = instance.unescape_field_name('field\"with\\\\mixed\"chars')
			expect(result).to be == 'field"with\\mixed"chars'
		end
		
		it "leaves normal field names unchanged" do
			result = instance.unescape_field_name("normal_field_name")
			expect(result).to be == "normal_field_name"
		end
		
		it "handles empty strings" do
			result = instance.unescape_field_name("")
			expect(result).to be == ""
		end
		
		it "is the inverse of escape_field_name" do
			original = 'field"with\\mixed"chars'
			escaped = instance.escape_field_name(original)
			unescaped = instance.unescape_field_name(escaped)
			expect(unescaped).to be == original
		end
	end
end
