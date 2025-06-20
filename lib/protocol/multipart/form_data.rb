# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "mixed"
require_relative "string_part"
require_relative "escape"

module Protocol
	module Multipart
		class FormData < Mixed
			include Escape
			
			def self.mime_type
				"multipart/form-data"
			end
			
			def add_field(name, value, headers = {})
				headers = headers.merge(
					"content-disposition" => "form-data; name=\"#{escape_field_name name}\""
				)
				
				@parts << StringPart.new(headers, value)
			end
		end
	end
end
