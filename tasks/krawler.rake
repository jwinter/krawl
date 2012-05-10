namespace :crawl do

  desc "Crawl a site looking for errors"
  task :base do
    url = ENV['URL'] || 'http://localhost:3000'
    Crawler.new(url).base
  end

end