# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Protocol
	module Multipart
		# Tracks consumed bytes against an optional maximum.
		class ByteLimit
			# Initialize a byte limit.
			# @parameter maximum [Integer | Nil] The maximum number of bytes, or nil for no limit.
			# @parameter name [Symbol] The name used when reporting a limit violation.
			def initialize(maximum, name: :size)
				if maximum and maximum < 0
					raise ArgumentError, "Multipart limits must be non-negative!"
				end
				
				@maximum = maximum
				@name = name
				@size = 0
			end
			
			# The number of bytes consumed.
			attr :size
			
			# Consume the given number of bytes.
			# @parameter size [Integer] The number of bytes to consume.
			# @returns [Integer] The total number of bytes consumed.
			def consume(size)
				@size += size
				
				if @maximum and @size > @maximum
					raise RangeError, "Multipart #{@name} exceeded limit of #{@maximum}!"
				end
				
				return @size
			end
		end
	end
end
