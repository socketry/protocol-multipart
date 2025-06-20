# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "part"

module Protocol
	module Multipart
		# A part that contains string content.
		class StringPart < Part
			def initialize(headers, content)
				super(headers)
				@content = content
			end
			
			attr_reader :content
			
			def call(writable, boundary)
				writable.write(@content)
			end
		end
	end
end
