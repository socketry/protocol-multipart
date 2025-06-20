# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "mixed"
require_relative "string_part"
require_relative "escape"

module Protocol
	module Multipart
		# FormData class for handling multipart/form-data format used in HTTP forms.
		# Extends Mixed to provide specific support for form fields with names and values.
		class FormData < Mixed
			include Escape
			
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
