require 'krawler/version'
require 'mechanize'
require 'timeout'

module Krawler

  class Base

    def initialize(url, options)
      @base = url
      @agent = Mechanize.new
      @links_to_crawl = [@base]
      @crawled_links  = []
      @bad_links      = []
      @suspect_links  = []
      @exclude        = options[:exclude]
    end
  
    def base
      puts "Crawling #{@base}"
    
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
        new_link = new_link.href
        if (new_link =~ /^#{Regexp.escape(@base)}/) || (new_link =~ /^\//)
          next if @crawled_links.include?(new_link)
          next if @exclude && new_link =~ /#{@exclude}/
    
          @links_to_crawl << new_link
        end
      end
    end
  end
end
