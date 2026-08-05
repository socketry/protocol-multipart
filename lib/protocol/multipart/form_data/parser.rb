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
				MEDIA_TYPE = "multipart/form-data"
				
				# Initialize the form data parser.
				# @parameter field_size_limit [Integer | Nil] The buffered field size limit.
				# @parameter upload_size_limit [Integer | Nil] The file upload size limit.
				# @parameter total_size_limit [Integer | Nil] The combined size limit for all fields and uploads.
				# @parameter depth_limit [Integer | Nil] The bracketed form name depth limit.
				# @parameter options [Hash] Limits passed to the underlying multipart parser.
				def initialize(field_size_limit: FIELD_SIZE_LIMIT, upload_size_limit: UPLOAD_SIZE_LIMIT, total_size_limit: TOTAL_SIZE_LIMIT, depth_limit: Protocol::URL::FormData::Nested::DEPTH_LIMIT, **options)
					if depth_limit and depth_limit < 0
						raise ArgumentError, "Form data limits must be non-negative!"
					end
					
					@field_size_limit = field_size_limit
					@upload_size_limit = upload_size_limit
					@total_size_limit = total_size_limit
					@depth_limit = depth_limit
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
					
					total_size_limit = ByteLimit.new(@total_size_limit, name: :total_size)
					parser = Multipart::Parser.new(readable, boundary, **@options)
					
					parser.each do |part|
						disposition = part.headers["content-disposition"]
						
						unless disposition&.type == "form-data" and name = disposition["name"]
							raise ArgumentError, "Multipart form part is missing a form-data name!"
						end
						
						if filename = disposition["filename"]
							upload = Upload.new(part, filename, @upload_size_limit, total_size_limit)
							yield name, upload
							upload.discard
						else
							field_size_limit = ByteLimit.new(@field_size_limit, name: :field_size)
							value = String.new.b
							
							part.each do |chunk|
								field_size_limit.consume(chunk.bytesize)
								total_size_limit.consume(chunk.bytesize)
								value << chunk
							end
							
							yield name, value
						end
					end
				end
				
				private
				
				def make_result
					return Protocol::URL::FormData::Nested.new(depth_limit: @depth_limit)
				end
			end
		end
	end
end
