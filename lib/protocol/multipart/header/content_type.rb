# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "parameterized"

module Protocol
	module Multipart
		module Header
			# A MIME Content-Type header value.
			class ContentType < Parameterized
				VALUE_PATTERN = /\A[ \t]*(#{TOKEN}\/#{TOKEN})[ \t]*/.freeze
				NAME = "content-type"
			end
		end
	end
end
