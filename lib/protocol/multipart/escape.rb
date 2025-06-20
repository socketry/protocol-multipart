# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

module Protocol
	module Multipart
		# Utilities for escaping and unescaping field names and values in multipart data
		module Escape
			# Escape field names according to RFC 7578 and RFC 2046
			# Quotes and backslashes need to be escaped with backslashes
			def escape_field_name(name)
				name.to_s.gsub(/([\\"])/, '\\\\\1')
			end
			
			# Unescape field names that were escaped with escape_field_name
			def unescape_field_name(name)
				name.to_s.gsub(/\\([\\"])/, '\1')
			end
		end
	end
end
