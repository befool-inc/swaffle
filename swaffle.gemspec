
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "swaffle/version"

Gem::Specification.new do |spec|
  spec.name          = "swaffle"
  spec.version       = Swaffle::VERSION
  spec.authors       = ["KIUCHI Satoshinosuke"]
  spec.email         = ["scholar@hayabusa-lab.jp"]

  spec.summary       = %q{Swagger API Library}
  spec.description   = %q{Swagger API Library}
  spec.homepage      = "https://github.com/befool-inc/swaffle"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = ["swaffle"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "ruby-swagger", "~> 0.1.1"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
