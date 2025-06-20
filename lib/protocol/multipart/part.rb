# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

module Protocol
	module Multipart
		# Represents a part in a multipart message.
		class Part
			def initialize(headers = {})
				@headers = headers
			end
			
			attr_accessor :headers
			
			# Writes the part to the writable body.
			#
			# @parameter writable [IO] The writable stream to write the part to.
			# @parameter boundary [String] The boundary string used to separate parts.
			def call(writable, boundary = nil)
			end
		end
	end
end
