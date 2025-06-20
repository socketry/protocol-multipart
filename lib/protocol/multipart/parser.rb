# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "io/stream"

module Protocol
	module Multipart
		class Parser
			class Part
				def initialize(readable, headers, boundary)
					@readable = readable
					@boundary = boundary
					@headers = headers
					@ended = false
					@is_closing = false
				end
				
				attr_reader :headers
				
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
				
				def read_empty_boundary?
					boundary_marker = "--#{@boundary}"
					if @readable.peek(boundary_marker.bytesize) == boundary_marker
						@readable.read(boundary_marker.bytesize)
						self.read_boundary_suffix
						
						return true
					end
					
					return false
				end
				
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
				
				def finish
					return unless @readable
					
					# Read all data until boundary
					data = @readable.read_until("\r\n--#{@boundary}", chomp: true)
					
					self.read_boundary_suffix
					
					return data
				end
				
				def discard
					# Efficiently discard all data until boundary
					return unless @readable
					
					# Discard data until boundary
					@readable.discard_until("\r\n--#{@boundary}")
					
					self.read_boundary_suffix
					
					return nil
				end
				
				def ended?
					@ended
				end
				
				def closing_boundary?
					@is_closing || (@readable.nil? && @is_closing)
				end
			end
			
			def initialize(readable, boundary)
				@readable = IO::Stream(readable)
				@boundary = boundary
				
				@boundary_marker = "--#{@boundary}\r\n".freeze
			end
			
			def each
				return to_enum unless block_given?
				
				# Read lines until we find the first boundary:
				while true
					if line = @readable.gets("\r\n", chomp: false)
						if line == @boundary_marker
							break
						end
					else
						# End of stream reached without finding boundary:
						raise EOFError, "No multipart boundary found in stream!"
					end
				end
				
				while true
					part = read_part
					break unless part
					
					if part.read_empty_boundary?
					else
						begin
							yield part
						ensure
							# After yielding, ensure the part is finished to advance to the next boundary. This is either a no-op if user already read the part, or reads remaining data.
							part.discard
						end
					end
					
					# Check if this was the last part:
					break if part.closing_boundary?
				end
				
				return true
			end
			
			private
			
			def read_part
				headers = {}
				value = nil
				
				# Read headers until empty line
				while line = @readable.gets("\r\n", chomp: true)
					if line.empty?
						break # End of headers
					elsif match = line.match(/^\s+([^:]+)$/)
						if value
							value << " " << match[1]
						else
							raise RuntimeError, "Unexpected whitespace before header name: #{line.inspect}"
						end
					elsif match = line.match(/^([^:]+):\s*(.*)$/) 
						# Parse header line (name: value)
						name = match[1].strip.downcase
						value = match[2].strip
						
						if current = headers[name]
							if current.is_a?(Array)
								current << value
							else
								headers[name] = [current, value]
							end
						else
							headers[name] = value
						end
					else
						raise RuntimeError, "Invalid header line: #{line.inspect}"
					end
				end
				
				unless line
					raise EOFError, "Unexpected end of stream while reading headers!"
				end
				
				return Part.new(@readable, headers, @boundary)
			end
		end
	end
end
