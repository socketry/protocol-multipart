# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "../form_data"

require "protocol/url/form_data/nested"

module Protocol
	module Multipart
		class FormData
			# A configurable parser for `multipart/form-data` bodies.
			class Parser
				CONTENT_TYPE = "multipart/form-data"
				
				# Initialize the form data parser.
				# @parameter maximum_field_size [Integer | Nil] The maximum size of each buffered field.
				# @parameter maximum_upload_size [Integer | Nil] The maximum size of each file upload.
				# @parameter maximum_total_size [Integer | Nil] The maximum combined size of all fields and uploads.
				# @parameter maximum_depth [Integer | Nil] The maximum depth of a bracketed form name.
				# @parameter options [Hash] Limits passed to the underlying multipart parser.
				def initialize(maximum_field_size: MAXIMUM_FIELD_SIZE, maximum_upload_size: MAXIMUM_UPLOAD_SIZE, maximum_total_size: MAXIMUM_TOTAL_SIZE, maximum_depth: Protocol::URL::FormData::Nested::MAXIMUM_DEPTH, **options)
					if maximum_depth and maximum_depth < 0
						raise ArgumentError, "Form data limits must be non-negative!"
					end
					
					@maximum_field_size = maximum_field_size
					@maximum_upload_size = maximum_upload_size
					@maximum_total_size = maximum_total_size
					@maximum_depth = maximum_depth
					@options = options
				end
				
				# Parse multipart form data into a nested hash.
				#
				# When a block is given, each value is passed through the block before assignment. The value returned by the block is assigned to the result. Uploads require a block because they must be consumed before parsing advances to the next part.
				#
				# @parameter readable [IO, IO::Stream] The readable stream containing multipart form data.
				# @parameter result [Object] The result to populate. It must support `#add` and `#to_h`.
				# @parameter boundary [String] The multipart boundary.
				# @yields {|name, value| ...} Each form entry before assignment.
				# @returns [Hash] The nested form data.
				def parse(readable, result = make_result, boundary:)
					each(readable, boundary:) do |name, value|
						if block_given?
							value = yield(name, value)
						elsif value.is_a?(Upload)
							raise ArgumentError, "A block is required to consume file uploads!"
						end
						
						result.add(name, value)
					end
					
					return result.to_h
				end
				
				# Incrementally enumerate multipart form data.
				#
				# Fields are yielded as strings. File uploads are yielded as streaming {Upload} instances and are only readable during the corresponding block invocation.
				#
				# @parameter readable [IO, IO::Stream] The readable stream containing multipart form data.
				# @parameter boundary [String] The multipart boundary.
				# @yields {|name, value| ...} Each form field name and its string or streaming upload value.
				# @returns [Enumerator | Boolean] An enumerator without a block, or true when complete.
				def each(readable, boundary:)
					return to_enum(__method__, readable, boundary:) unless block_given?
					
					total_limit = ByteLimit.new(@maximum_total_size, name: :total_size)
					parser = Multipart::Parser.new(readable, boundary, **@options)
					
					parser.each do |part|
						disposition = part.headers["content-disposition"]
						
						unless disposition&.type == "form-data" and name = disposition["name"]
							raise ArgumentError, "Multipart form part is missing a form-data name!"
						end
						
						if filename = disposition["filename"]
							upload = Upload.new(part, filename, @maximum_upload_size, total_limit)
							yield name, upload
							upload.discard
						else
							field_limit = ByteLimit.new(@maximum_field_size, name: :field_size)
							value = String.new.b
							
							part.each do |chunk|
								field_limit.consume(chunk.bytesize)
								total_limit.consume(chunk.bytesize)
								value << chunk
							end
							
							yield name, value
						end
					end
				end
				
				private
				
				def make_result
					return Protocol::URL::FormData::Nested.new(maximum_depth: @maximum_depth)
				end
			end
		end
	end
end
