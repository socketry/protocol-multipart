# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/multipart/readable"

require "stringio"
require "tmpdir"

describe Protocol::Multipart::Readable do
	let(:readable) do
		Class.new do
			include Protocol::Multipart::Readable
			
			def each(chunk_size = 8192)
				return to_enum(:each, chunk_size) unless block_given?
				
				yield "content"
			end
		end.new
	end
	
	it "copies content to a writable object" do
		output = StringIO.new
		
		expect(readable.copy_to(output)).to be == 7
		expect(output.string).to be == "content"
	end
	
	it "handles partial writes" do
		output = String.new
		writable = Object.new
		writable.define_singleton_method(:write) do |chunk|
			output << chunk.byteslice(0, 1)
			1
		end
		
		expect(readable.copy_to(writable)).to be == 7
		expect(output).to be == "content"
	end
	
	it "rejects writes which cannot make progress" do
		writable = Object.new
		writable.define_singleton_method(:write){|_chunk| 0}
		
		expect do
			readable.copy_to(writable)
		end.to raise_exception(IOError, message: be =~ /make progress/)
	end
	
	it "saves content to a new private file" do
		Dir.mktmpdir do |directory|
			path = File.join(directory, "content")
			
			expect(readable.save(path)).to be == 7
			expect(File.binread(path)).to be == "content"
			expect(File.stat(path).mode & 0o777).to be == 0o600
		end
	end
	
	it "does not replace an existing file" do
		Dir.mktmpdir do |directory|
			path = File.join(directory, "content")
			File.write(path, "existing")
			
			expect do
				readable.save(path)
			end.to raise_exception(Errno::EEXIST)
			
			expect(File.read(path)).to be == "existing"
		end
	end
	
	it "removes a partial file when copying fails" do
		readable.define_singleton_method(:each) do |_chunk_size = 8192, &block|
			block.call("partial")
			raise "Copy failed!"
		end
		
		Dir.mktmpdir do |directory|
			path = File.join(directory, "content")
			
			expect do
				readable.save(path)
			end.to raise_exception(RuntimeError, message: be == "Copy failed!")
			
			expect(File.exist?(path)).to be == false
		end
	end
end
