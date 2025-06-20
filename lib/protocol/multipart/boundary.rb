# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "securerandom"

module Protocol
	module Multipart
		# Generate a secure boundary string for multipart messages.
		# Approximately 192 bits of entropy by default, which is sufficient for most applications.
		def self.secure_boundary(prefix = nil, length = 24)
			if prefix
				"#{prefix}-#{SecureRandom.urlsafe_base64(length, false)}"
			else
				SecureRandom.urlsafe_base64(length, false)
			end
		end
	end
end
