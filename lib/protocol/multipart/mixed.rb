# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require_relative "part"
require_relative "boundary"

module Protocol
	module Multipart
		# Represents a multipart/mixed message.
		class Mixed < Part
			def self.mime_type
				"multipart/mixed"
			end
			
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
