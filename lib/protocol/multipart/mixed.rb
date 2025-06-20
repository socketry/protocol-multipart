# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "part"
require_relative "boundary"

module Protocol
	module Multipart
		# Represents a multipart/mixed message.
		# A composite part that contains multiple nested parts with a boundary separator.
		class Mixed < Part
			# Returns the MIME type for mixed multipart data.
			#
			# @returns [String] The MIME type "multipart/mixed".
			def self.mime_type
				"multipart/mixed"
			end
			
			# Initialize a new multipart/mixed container.
			#
			# @parameter headers [Hash] Headers for the multipart container.
			# @parameter parts [Array] The parts to include in this multipart container.
			# @parameter boundary [String] The boundary string to use for separating parts.
			# @parameter mime_type [String] The MIME type to use for this container.
			def initialize(headers = {}, parts = [], boundary: Multipart.secure_boundary, mime_type: self.class.mime_type)
				super(headers)
				
				@boundary = boundary
				@parts = parts
				@headers["content-type"] = "#{mime_type}; boundary=#{@boundary}"
			end
			
			# @attribute [String] The boundary string used to separate parts.
			attr :boundary
			
			# @attribute [Array(Part)] The parts of the body.
			attr :parts
			
			private def write_headers(writable, headers)
				headers.each do |key, value|
					writable.write("#{key}: #{value}\r\n")
				end
				
				writable.write("\r\n")
			end
			
			# Writes the multipart container and all its parts to the writable stream.
			# This method serializes the multipart container, including all nested parts,
			# with appropriate boundaries between them.
			#
			# @parameter writable [IO] The writable stream to write the multipart data to.
			# @parameter boundary [String | Nil] The parent boundary string, if this is a nested multipart.
			def call(writable, boundary = nil)
				return if @parts.empty?
				
				first = true
				initial_boundary = "--#{@boundary}\r\n".freeze
				middle_boundary = "\r\n--#{@boundary}\r\n".freeze
				
				# Write each part:
				@parts.each do |part|
					if first
						# Write the initial boundary:
						writable.write(initial_boundary)
						first = false
					else
						# Write the boundary before each part:
						writable.write(middle_boundary)
					end
					
					self.write_headers(writable, part.headers)
					part.call(writable, middle_boundary)
				end
				
				unless first
					# Write the final boundary:
					writable.write("\r\n--#{@boundary}--\r\n")
				end
			end
		end
	end
end
