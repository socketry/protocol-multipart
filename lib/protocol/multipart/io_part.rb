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
			
			# Opens a file and creates an IOPart for it.
			#
			# @parameter path [String] The file path to open.
			# @parameter mime_type [String | Nil] The MIME type of the file, or nil to use application/octet-stream.
			# @parameter name [String | Nil] The name to use for the file, or nil to use the filename.
			# @parameter headers [Hash] Additional headers for the part.
			# @returns [IOPart] A new IOPart instance for the file.
			def self.open(path, mime_type: nil, name: nil, headers: {})
				io = File.open(path, "rb")
				
				name ||= File.basename(path)
				
				headers = headers.merge(
					"content-disposition" => "attachment; filename=\"#{escape_field_name name}\"",
					"content-type" => mime_type || "application/octet-stream"
				)
				
				return new(headers, io)
			end
			
			# Initialize a new IOPart with the given headers and IO object.
			#
			# @parameter headers [Hash] Headers for the part.
			# @parameter io [IO] The IO object containing the part's data.
			def initialize(headers, io)
				super(headers)
				@io = io
			end
			
			# The underlying IO object.
			# @attribute [IO] The IO object containing the part's data.
			attr_reader :io
			
			# Write the part's content to the provided writable stream.
			#
			# @parameter writable [IO] The destination stream to write to.
			# @parameter boundary [String] The boundary string for the multipart message.
			def call(writable, boundary)
				while chunk = @io.read(8192)
					break if chunk.empty?
					writable.write(chunk)
				end
			end
		end
	end
end
