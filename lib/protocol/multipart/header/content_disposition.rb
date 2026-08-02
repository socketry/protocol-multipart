# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "parameterized"

module Protocol
	module Multipart
		module Header
			# A MIME Content-Disposition header value.
			class ContentDisposition < Parameterized
				VALUE_PATTERN = /\A[ \t]*(#{TOKEN})[ \t]*/.freeze
				NAME = "content-disposition"
			end
		end
	end
end
