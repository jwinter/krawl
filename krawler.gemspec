# -*- encoding: utf-8 -*-
require File.expand_path('../lib/krawler/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mike Evans"]
  gem.email         = ["mike@urlgonomics.com"]
  gem.description   = %q{Simple little rake task to crawl a site.}
  gem.summary       = %q{}
  gem.homepage      = ""

  gem.add_dependency 'mechanize', '~> 2.5.0'
  gem.rubyforge_project = 'krawler'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "krawler"
  gem.require_paths = ["lib"]
  gem.version       = Krawler::VERSION
end
