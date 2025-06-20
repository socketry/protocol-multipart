# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "part"

module Protocol
	module Multipart
		# A part that contains string content.
		# Represents a multipart part with string data.
		class StringPart < Part
			# Initialize a new StringPart with headers and string content.
			#
			# @parameter headers [Hash] Headers for the part.
			# @parameter content [String] The string content of the part.
			def initialize(headers, content)
				super(headers)
				@content = content
			end
			
			# @attribute [String] The content of the part.
			attr_reader :content
			
			# Write the part's content to the provided writable stream.
			#
			# @parameter writable [IO] The destination stream to write to.
			# @parameter boundary [String] The boundary string for the multipart message.
			def call(writable, boundary)
				writable.write(@content)
			end
		end
	end
end
