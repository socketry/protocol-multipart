# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "mixed"
require_relative "parser"
require_relative "string_part"
require_relative "escape"
require_relative "byte_limit"

module Protocol
	module Multipart
		# FormData class for handling multipart/form-data format used in HTTP forms.
		# Extends Mixed to provide specific support for form fields with names and values.
		class FormData < Mixed
			include Escape
			
			# The default maximum size of a buffered form field.
			MAXIMUM_FIELD_SIZE = 2 * 1024 * 1024
			
			# The default maximum size of a streamed file upload.
			MAXIMUM_UPLOAD_SIZE = 128 * 1024 * 1024
			
			# The default maximum combined size of all form fields and file uploads.
			MAXIMUM_TOTAL_SIZE = 256 * 1024 * 1024
			
			# A file upload yielded while parsing form data.
			class Upload
				# Initialize a streamed file upload.
				# @parameter part [Parser::Part] The underlying multipart part.
				# @parameter filename [String] The submitted filename.
				# @parameter maximum_size [Integer | Nil] The maximum upload size.
				# @parameter total_limit [ByteLimit] The shared form-data size limit.
				def initialize(part, filename, maximum_size, total_limit)
					@part = part
					@filename = filename
					@limit = ByteLimit.new(maximum_size, name: :upload_size)
					@total_limit = total_limit
				end
				
				# The submitted filename.
				attr :filename
				
				# The multipart headers associated with this upload.
				def headers
					@part.headers
				end
				
				# The number of upload bytes consumed so far.
				def size
					@limit.size
				end
				
				# Whether the complete upload has been consumed.
				def ended?
					@part.ended?
				end
				
				# Iterate over the upload body.
				# @parameter chunk_size [Integer] The maximum chunk size.
				def each(chunk_size = 8192)
					return to_enum(:each, chunk_size) unless block_given?
					
					@part.each(chunk_size) do |chunk|
						@limit.consume(chunk.bytesize)
						@total_limit.consume(chunk.bytesize)
						yield chunk
					end
					
					return self
				end
				
				# Consume any unread upload body while applying its limits.
				def discard
					self.each{|chunk|}
					return nil
				end
			end
			
			# Returns the MIME type for form data.
			#
			# @returns [String] The MIME type "multipart/form-data".
			def self.mime_type
				"multipart/form-data"
			end
			
			# Adds a form field to the multipart form data.
			#
			# @parameter name [String] The field name.
			# @parameter value [String] The field value.
			# @parameter headers [Hash] Additional headers for the field.
			# @returns [StringPart] The created StringPart for the field.
			def add_field(name, value, headers = {})
				headers = headers.merge(
					"content-disposition" => "form-data; name=\"#{escape_field_name name}\""
				)
				
				StringPart.new(headers, value).tap do |part|
					@parts << part
				end
			end
		end
	end
end

require_relative "form_data/parser"
