require 'krawler/version'
require 'mechanize'
require 'timeout'
require 'uri'
require 'pry'

module Krawler

  class Base

    def initialize(url, options)
      url = URI(url)
      @host           = "#{url.scheme}://#{url.host}"
      @base_path      = url.path
      @agent          = Mechanize.new
      @links_to_crawl = [url]
      @crawled_links  = []
      @bad_links      = []
      @suspect_links  = []
      @exclude        = options[:exclude]
      @restrict       = options[:restrict]
    end
  
    def base
      puts "Crawling..."

      while !@links_to_crawl.empty? do
        crawl_page(@links_to_crawl.pop)
      end
    
      puts "#{@crawled_links.size} total Good Links"
    
      puts "Bad Links:"
      @bad_links.each {|link| puts link }
    
      puts "Suspect Links:"
      @suspect_links.each {|link| puts link}
    end
  
    def crawl_page(link)
      @crawled_links << link
      puts link
      begin
        start = Time.now
        page = @agent.get(link)
      rescue Mechanize::ResponseCodeError => e
        puts e
        @bad_links << link
        return
      rescue Timeout::Error => e
        @suspect_links << link
        return
      ensure
        puts "    [#{Time.now - start}s] #{@links_to_crawl.size} links..."
      end
  
      return if !page.respond_to?(:links)
      page.links.each do |new_link|
        begin
          new_url = URI(new_link.href)
          new_link = new_url.to_s
        rescue ArgumentError # junk link
          next
        end

        if (new_link =~ /^#{Regexp.escape(@host)}/) || (new_link =~ /^\//) # don't crawl external domains

          next if @crawled_links.include?(new_link)       # don't crawl what we've alread crawled
          next if @exclude && new_link =~ /#{@exclude}/   # don't crawl excluded matched paths
          next if @restrict && (new_url.path !~ /^#{Regexp.escape(@base_path)}/) # don't crawl outside of our restricted base path
          
          @links_to_crawl << new_link
        end
      end
    end
  end
end
