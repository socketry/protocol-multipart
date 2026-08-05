# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/multipart/byte_limit"

describe Protocol::Multipart::ByteLimit do
	it "tracks consumed bytes" do
		limit = subject.new(4)
		
		expect(limit.consume(2)).to be == 2
		expect(limit.size).to be == 2
	end
	
	it "raises when the maximum is exceeded" do
		limit = subject.new(1, name: :field_size)
		
		expect{limit.consume(2)}.to raise_exception(Protocol::Multipart::LimitError, message: be =~ /field_size exceeded limit of 1/)
	end
	
	it "can be unlimited" do
		limit = subject.new(nil)
		
		expect(limit.consume(1024)).to be == 1024
	end
	
	it "rejects a negative maximum" do
		expect{subject.new(-1)}.to raise_exception(ArgumentError, message: be =~ /must be non-negative/)
	end
end
