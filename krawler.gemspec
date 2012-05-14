# -*- encoding: utf-8 -*-
require File.expand_path('../lib/krawler/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mike Evans"]
  gem.email         = ["mike@urlgonomics.com"]
  gem.description   = %q{Simple little website crawler.}
  gem.summary       = %q{}
  gem.homepage      = 'https://github.com/mje113/krawl'

  gem.add_dependency 'mechanize', '~> 2.5.0'
  gem.rubyforge_project = 'krawler'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.bindir        = 'bin'
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "krawler"
  gem.require_paths = ["lib"]
  gem.version       = Krawler::VERSION
end
