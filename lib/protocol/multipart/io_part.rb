# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "part"
require_relative "escape"

module Protocol
	module Multipart
		# A part that contains IO content (files, streams, etc.).
		class IOPart < Part
			extend Escape
			
			def self.open(path, mime_type: nil, name: nil, headers: {})
				io = File.open(path, "rb")
				
				name ||= File.basename(path)
				
				headers = headers.merge(
					"content-disposition" => "attachment; filename=\"#{escape_field_name name}\"",
					"content-type" => mime_type || "application/octet-stream"
				)
				
				return new(headers, io)
			end
			
			def initialize(headers, io)
				super(headers)
				@io = io
			end
			
			attr_reader :io
			
			def call(writable, boundary)
				while chunk = @io.read(8192)
					break if chunk.empty?
					writable.write(chunk)
				end
			end
		end
	end
end
