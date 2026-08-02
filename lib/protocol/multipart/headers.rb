# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/headers"

require_relative "header/content_disposition"
require_relative "header/content_type"

module Protocol
	module Multipart
		# @namespace
		module Header
		end
		
		# The header fields associated with a multipart body or part.
		class Headers < Protocol::HTTP::Headers
			POLICY = {
				"content-description" => false,
				"content-disposition" => Header::ContentDisposition,
				"content-id" => false,
				"content-length" => false,
				"content-transfer-encoding" => false,
				"content-type" => Header::ContentType,
				"mime-version" => false,
			}.tap do |policy|
				policy.default = Protocol::HTTP::Header::Multiple
			end
			
			# Initialize the multipart headers.
			# @parameter fields [Array] An array of `[key, value]` pairs.
			# @parameter tail [Integer | Nil] The index of the trailer start.
			# @parameter indexed [Hash | Nil] The cached header index.
			# @parameter policy [Hash] The header normalization policy.
			def initialize(fields = [], tail = nil, indexed: nil, policy: POLICY)
				super
			end
		end
	end
end
