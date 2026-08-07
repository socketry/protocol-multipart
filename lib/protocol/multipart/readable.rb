# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Protocol
	module Multipart
		# Common operations for streaming readable multipart content.
		module Readable
			# Copy the content to a writable object.
			# @parameter output [#write] The writable destination.
			# @parameter chunk_size [Integer] The maximum chunk size.
			# @returns [Integer] The number of bytes copied.
			def copy_to(output, chunk_size = 8192)
				size = 0
				
				each(chunk_size) do |chunk|
					offset = 0
					
					# A writable object may consume only part of a chunk:
					while offset < chunk.bytesize
						written = output.write(chunk.byteslice(offset, chunk.bytesize - offset))
						
						unless written && written > 0
							raise IOError, "Could not make progress while copying multipart content!"
						end
						
						offset += written
					end
					
					size += chunk.bytesize
				end
				
				return size
			end
			
			# Save the content to a new local file.
			# @parameter path [String, #to_path] The destination path, which must not exist.
			# @parameter permissions [Integer] The permissions for the new file.
			# @parameter chunk_size [Integer] The maximum chunk size.
			# @returns [Integer] The number of bytes saved.
			def save(path, permissions: 0o600, chunk_size: 8192)
				flags = File::WRONLY | File::CREAT | File::EXCL
				created = false
				
				begin
					File.open(path, flags, permissions) do |file|
						created = true
						file.binmode
						return copy_to(file, chunk_size)
					end
				rescue
					# Remove a partial destination created by this operation:
					if created
						File.unlink(path)
					end
					
					raise
				end
			end
		end
	end
end
