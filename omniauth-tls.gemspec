
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'omniauth-tls'
  spec.version       = File.read(File.expand_path('../VERSION', __FILE__)).strip
  spec.authors       = ['Christian Mader']
  spec.email         = ['cma@nine.ch']

  spec.summary       = 'A TLS client certificate omniauth strategy'
  spec.description   = %q{This is an omniauth strategy, that authenticates user based on request variables provided
by Apache HTTP, NGINX, etc.}
  spec.homepage      = 'https://github.com/ninech/omniauth-tls'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    # spec.metadata['allowed_push_host'] = 'https://rubygems.org'
    spec.metadata['allowed_push_host'] = 'https://rubygems.nine.ch/private'
  end

  # spec.files         = `git ls-files -z`.split("\x0").reject do |f|
  #   f.match(%r{^(test|spec|features)/})
  # end

  spec.files         = Dir['lib/   *.rb'] + Dir['bin/*']
  spec.files        += Dir['[A-Z]*'] + Dir['spec/**/*']
  spec.files.reject! { |fn| fn.include? ".git" }

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_runtime_dependency 'omniauth', '~> 1.0'
end
