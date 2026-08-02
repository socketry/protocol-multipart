# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Protocol
	module Multipart
		# A parameterized header value, such as Content-Type or Content-Disposition.
		class Header
			TOKEN = "[!#$%&'*+\\-.^_`|~0-9A-Za-z]+"
			VALUE_PATTERN = /\A\s*(#{TOKEN}(?:\/#{TOKEN})?)\s*/.freeze
			PARAMETER_PATTERN = /\G;\s*(#{TOKEN})\s*=\s*(?:"((?:\\[^\r\n]|[^"\\\r\n])*)"|(#{TOKEN}))\s*/.freeze
			
			# Parse a parameterized header value.
			# @parameter string [String] The header value.
			# @returns [Header] The parsed header.
			# @raises [ArgumentError] If the header value is malformed or contains duplicate parameters.
			def self.parse(string)
				unless match = VALUE_PATTERN.match(string)
					raise ArgumentError, "Invalid header value: #{string.inspect}!"
				end
				
				type = match[1].downcase
				parameters = {}
				offset = match.end(0)
				
				while offset < string.bytesize
					unless match = PARAMETER_PATTERN.match(string, offset)
						raise ArgumentError, "Invalid header parameter at offset #{offset}: #{string.inspect}!"
					end
					
					name = match[1].downcase
					
					if parameters.key?(name)
						raise ArgumentError, "Duplicate header parameter: #{name.inspect}!"
					end
					
					if quoted = match[2]
						parameters[name] = quoted.gsub(/\\(.)/, "\\1")
					else
						parameters[name] = match[3]
					end
					
					offset = match.end(0)
				end
				
				return new(type, parameters)
			end
			
			# Initialize a parameterized header value.
			# @parameter type [String] The primary header value.
			# @parameter parameters [Hash] The named parameters.
			def initialize(type, parameters = {})
				@type = type
				@parameters = parameters
			end
			
			# The primary header value.
			attr :type
			
			# The named parameters.
			attr :parameters
			
			# Fetch a named parameter.
			# @parameter name [String] The case-insensitive parameter name.
			# @returns [String | Nil] The parameter value, if present.
			def [](name)
				@parameters[name.downcase]
			end
		end
	end
end
