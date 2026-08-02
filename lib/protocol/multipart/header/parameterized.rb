# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/error"

module Protocol
	module Multipart
		module Header
			# A parameterized MIME header value.
			class Parameterized
				TOKEN = "[!#$%&'*+\\-.^_`|~0-9A-Za-z]+"
				VALUE_PATTERN = /\A[ \t]*(#{TOKEN}(?:\/#{TOKEN})?)[ \t]*/.freeze
				PARAMETER_PATTERN = /\G;[ \t]*(#{TOKEN})[ \t]*=[ \t]*(?:"((?:\\[^\x00-\x1f\x7f]|[^"\\\x00-\x1f\x7f])*)"|(#{TOKEN}))[ \t]*/.freeze
				NAME = nil
				
				# Parse a parameterized header value.
				# @parameter string [String] The header value.
				# @returns [Parameterized] The parsed header.
				# @raises [ArgumentError] If the header value is malformed or contains duplicate parameters.
				def self.parse(string)
					unless match = self::VALUE_PATTERN.match(string)
						raise ArgumentError, "Invalid header value: #{string.inspect}!"
					end
					
					type = match[1].downcase
					parameters = {}
					offset = match.end(0)
					
					while offset < string.length
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
				
				# Coerce an object to a parameterized header value.
				# @parameter value [Object] The header value.
				# @returns [Parameterized] The parsed header.
				def self.coerce(value)
					if value.is_a?(self)
						return value
					end
					
					return parse(value.to_s)
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
				
				# Reject a second value for this singular MIME field.
				def <<(value)
					raise Protocol::HTTP::DuplicateHeaderError.new(self.class::NAME, self, value)
				end
				
				# Convert the header to its wire representation.
				# @returns [String] The serialized header value.
				def to_s
					value = String.new(@type)
					
					@parameters.each do |name, parameter|
						escaped = parameter.gsub(/["\\]/, "\\\\\\0")
						value << "; #{name}=\"#{escaped}\""
					end
					
					return value
				end
			end
		end
	end
end
