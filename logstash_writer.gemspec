begin
  require 'git-version-bump'
rescue LoadError
  nil
end

Gem::Specification.new do |s|
  s.name = "logstash_writer"

  s.version = GVB.version rescue "0.0.0.1.NOGVB"
  s.date    = GVB.date    rescue Time.now.strftime("%Y-%m-%d")

  s.platform = Gem::Platform::RUBY

  s.summary  = "Opinionated logstash event pump"
  s.description = <<~EOF
    Takes events from anything you like, and reliably sends them to a
    logstash server (or cluster thereof), using modern service discovery
    techniques like DNS.
  EOF

  s.authors  = ["Matt Palmer"]
  s.email    = ["matt.palmer@discourse.org"]
  s.homepage = "https://github.com/discourse/logstash_writer"

  s.files = `git ls-files -z`.split("\0").reject { |f| f =~ /^(G|spec|Rakefile)/ }

  s.required_ruby_version = ">= 2.3.0"

  # prometheus-client provides no guaranteed backwards compatibility,
  # and in fact happily breaks things with no notice, so we're stuck
  # with hard-coding a specific version to avoid unexpected disaster.
  s.add_runtime_dependency "prometheus-client", "0.8.0"

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'github-release'
  s.add_development_dependency 'git-version-bump'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'guard-rubocop'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rake', "~> 12.0"
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'yard'
end
