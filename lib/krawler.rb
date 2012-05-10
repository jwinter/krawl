require 'krawler/version'
require 'mechanize'

module Krawler

  class Base

    def initialize(url)
      @base = url
      @agent = Mechanize.new
      @links_to_crawl = [@base]
      @crawled_links  = []
      @bad_links      = []
      @suspect_links  = []
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
        puts "SLOW PAGE, timeout at #{Time.now - start} seconds"
        @suspect_links << link
        return
      end
  
      elapsed = Time.now - start
      if elapsed > 7.0
        puts "SLOW PAGE, #{Time.now - start} seconds"
      end
  
      return if !page.respond_to?(:links)
      page.links.each do |new_link|
        new_link = new_link.href
        if (new_link =~ /^#{Regexp.escape(@base)}/) || (new_link =~ /^\//)
          next if @crawled_links.include?(new_link)
    
          @links_to_crawl << new_link
        end
      end
    end
  end
end
