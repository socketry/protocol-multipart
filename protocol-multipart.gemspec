# frozen_string_literal: true

require_relative "lib/protocol/multipart/version"

Gem::Specification.new do |spec|
	spec.name = "protocol-multipart"
	spec.version = Protocol::Multipart::VERSION
	
	spec.summary = "Provides abstractions to handle the multipart format."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.homepage = "https://github.com/socketry/protocol-multipart"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/protocol-multipart/",
		"source_code_uri" => "https://github.com/socketry/protocol-multipart.git",
	}
	
	spec.files = Dir.glob(["{lib}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.3"
	
	spec.add_dependency "io-stream", "~> 0.8"
	spec.add_dependency "protocol-http", "~> 0.67"
	spec.add_dependency "protocol-url", "~> 0.9"
end
