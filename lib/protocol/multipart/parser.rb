# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "io/stream"
require_relative "headers"

module Protocol
	module Multipart
		# A parser for multipart data based on RFC 2046 and RFC 2387.
		# Parses multipart bodies and provides an enumerable interface to access the parts.
		class Parser
			HEADER_PATTERN = /\A([!-9;-~]+):[ \t]*([^\x00-\x08\x0a-\x1f\x7f]*)\z/.freeze
			private_constant :HEADER_PATTERN
			
			# The preamble size limit.
			PREAMBLE_SIZE_LIMIT = 64 * 1024
			
			# The header size limit for each part.
			HEADER_SIZE_LIMIT = 64 * 1024
			
			# The header count limit for each part.
			HEADER_COUNT_LIMIT = 64
			
			# The part count limit.
			PART_COUNT_LIMIT = 128
			
			# Represents a single part within a multipart message.
			class Part
				# Initialize a new part with a readable stream, headers, and a boundary string.
				#
				# @parameter readable [IO::Stream] The readable stream that contains the part's data.
				# @parameter headers [Headers] The headers associated with this part.
				# @parameter boundary [String] The boundary string used to separate parts.
				def initialize(readable, headers, boundary)
					@readable = readable
					@boundary = boundary
					@headers = headers
					@ended = false
					@is_closing = false
				end
				
				# @attribute [Headers] The headers associated with this part.
				attr_reader :headers
				
				# Iterate through the part content in chunks.
				#
				# @parameter chunk_size [Integer] The size of each chunk to read.
				# @returns [Enumerable] An enumerable of content chunks if no block given.
				def each(chunk_size = 8192)
					return to_enum(:each, chunk_size) unless block_given?
					
					return unless @readable
					
					boundary_marker = "\r\n--#{@boundary}"
					
					# Stream data in chunks using read_until with a limit
					while @readable
						if chunk = @readable.read_until(boundary_marker, limit: chunk_size, chomp: true)
							# We found the boundary, check if it's a closing boundary:
							if suffix = @readable.read_until("\r\n", chomp: true)
								@is_closing = (suffix == "--")
								@ended = true
								@readable = nil
							else
								@readable = nil
								raise EOFError, "Unexpected end of stream while reading part data!"
							end
						else
							chunk = @readable.read(chunk_size)
						end
						
						if chunk
							yield chunk unless chunk.empty?
						else
							# No more data to read, break the loop:
							break
						end
					end
				end
				
				# Checks if the next content is an empty boundary (part with no content).
				#
				# @returns [Boolean] True if an empty boundary was found and read, false otherwise.
				def read_empty_boundary?
					boundary_marker = "--#{@boundary}"
					if @readable.peek(boundary_marker.bytesize) == boundary_marker
						@readable.read(boundary_marker.bytesize)
						self.read_boundary_suffix
						
						return true
					end
					
					return false
				end
				
				# Reads the suffix after a boundary to determine if it's a closing boundary.
				def read_boundary_suffix
					# Read the rest of the boundary line to check if it's closing:
					boundary_suffix = @readable.read(2)
					if boundary_suffix == "--"
						@is_closing = true
						@ended = true
						@readable = nil
					elsif boundary_suffix == "\r\n"
						@is_closing = false
						@ended = true
						@readable = nil
					else
						@readable = nil
						raise EOFError, "Unexpected end of stream while reading part data!"
					end
				end
				
				# Finishes reading this part's data and advances to the next boundary.
				# 
				# @returns [String | Nil] The remaining content of the part, or nil if already finished.
				def finish
					return unless @readable
					
					# Read all data until boundary
					data = @readable.read_until("\r\n--#{@boundary}", chomp: true)
					
					self.read_boundary_suffix
					
					return data
				end
				
				# Efficiently discards all data until the next boundary is found.
				# This is used to skip parts without reading their content into memory.
				#
				# @returns [Nil]
				def discard
					# Efficiently discard all data until boundary
					return unless @readable
					
					# Discard data until boundary
					@readable.discard_until("\r\n--#{@boundary}")
					
					self.read_boundary_suffix
					
					return nil
				end
				
				# Checks if this part has been completely read.
				#
				# @returns [Boolean] True if this part has been completely read.
				def ended?
					@ended
				end
				
				# Checks if this part ends with a closing boundary.
				# A closing boundary indicates that this is the last part in the multipart message.
				#
				# @returns [Boolean] True if this part ends with a closing boundary.
				def closing_boundary?
					@is_closing || (@readable.nil? && @is_closing)
				end
			end
			
			# Initialize a new multipart parser.
			#
			# @parameter readable [IO, IO::Stream] The readable stream containing multipart data.
			# @parameter boundary [String] The boundary string that separates the parts.
			# @parameter preamble_size_limit [Integer | Nil] The preamble size limit, or nil for no limit.
			# @parameter header_size_limit [Integer | Nil] The header size limit per part, or nil for no limit.
			# @parameter header_count_limit [Integer | Nil] The header count limit per part, or nil for no limit.
			# @parameter part_count_limit [Integer | Nil] The part count limit, or nil for no limit.
			def initialize(readable, boundary, preamble_size_limit: PREAMBLE_SIZE_LIMIT, header_size_limit: HEADER_SIZE_LIMIT, header_count_limit: HEADER_COUNT_LIMIT, part_count_limit: PART_COUNT_LIMIT)
				limits = [preamble_size_limit, header_size_limit, header_count_limit, part_count_limit]
				
				if limits.any?{|limit| limit and limit < 0}
					raise ArgumentError, "Multipart limits must be non-negative!"
				end
				
				@readable = IO::Stream(readable)
				@boundary = boundary
				@preamble_size_limit = preamble_size_limit
				@header_size_limit = header_size_limit
				@header_count_limit = header_count_limit
				@part_count_limit = part_count_limit
				
				@boundary_marker = "--#{@boundary}\r\n".freeze
			end
			
			# Enumerate through each part in the multipart data.
			# Yields each part for processing. If no block is given, returns an enumerator.
			#
			# @returns [Enumerator, Boolean] An enumerator if no block given, or true when complete.
			def each
				return to_enum unless block_given?
				
				preamble_size = 0
				
				# Read lines until we find the first boundary:
				while true
					if line = read_line(preamble_size, @preamble_size_limit, allowance: @boundary_marker.bytesize, chomp: false)
						if line == @boundary_marker
							break
						else
							preamble_size += line.bytesize
							check_limit(:preamble_size, preamble_size, @preamble_size_limit)
						end
					else
						# End of stream reached without finding boundary:
						raise EOFError, "No multipart boundary found in stream!"
					end
				end
				
				part_count = 0
				
				while true
					part_count += 1
					check_limit(:part_count, part_count, @part_count_limit)
					
					part = read_part
					break unless part
					
					if part.read_empty_boundary?
					else
						yield part
						
						# Advance to the next boundary after the consumer returns normally. If the consumer raises, stop parsing without draining the request body.
						part.discard
					end
					
					# Check if this was the last part:
					break if part.closing_boundary?
				end
				
				return true
			end
			
			private
			
			def read_line(size, limit, allowance: 0, chomp:)
				if limit
					limit = limit - size + allowance + 1
					return @readable.gets("\r\n", limit, chomp: chomp)
				else
					return @readable.gets("\r\n", chomp: chomp)
				end
			end
			
			def check_limit(name, value, limit)
				if limit and value > limit
					raise RangeError, "Multipart #{name} exceeded limit of #{limit}!"
				end
			end
			
			def read_part
				fields = []
				header_size = 0
				header_count = 0
				
				# Read headers until empty line
				while line = read_line(header_size, @header_size_limit, allowance: 2, chomp: true)
					if line.empty?
						break # End of headers
					end
					
					header_size += line.bytesize + 2
					check_limit(:header_size, header_size, @header_size_limit)
					
					if match = line.match(HEADER_PATTERN)
						# Parse header line (name: value)
						header_count += 1
						check_limit(:header_count, header_count, @header_count_limit)
						
						fields << [match[1], match[2].strip]
					else
						raise RuntimeError, "Invalid header line: #{line.inspect}"
					end
				end
				
				unless line
					raise EOFError, "Unexpected end of stream while reading headers!"
				end
				
				return Part.new(@readable, Headers.new(fields), @boundary)
			end
		end
	end
end
