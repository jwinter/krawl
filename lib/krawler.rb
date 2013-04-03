require 'krawler/version'
require 'krawler/authentication'
require 'mechanize'
require 'timeout'
require 'uri'
require 'thread'
#require 'pry'

module Krawler

  class Base

    include Authentication

    def initialize(url, options)
      @url              = URI(url)
      @host             = "#{@url.scheme}://#{@url.host}"
      @base_path        = @url.path
      @links_to_crawl   = [@url.to_s]
      @crawled_links    = []
      @bad_links        = []
      @suspect_links    = []
      @exclude          = options[:exclude]
      @include          = options[:include]
      @restrict         = options[:restrict]
      @domain           = options[:domain]
      @randomize        = options[:randomize]
      @threads          = options[:threads]   || 1
      @username         = options[:username]
      @password         = options[:password]
      @login_url        = options[:login_url]
      @mutex            = Mutex.new
      @agent            = Mechanize.new
      @agent.user_agent = 'Krawler'
      @agent.ssl_version = 'SSLv3'
      @headers           = { 'Accept-Encoding' => 'gzip, deflate' }
      @headers['Cache-Control'] = 'no-cache' if options[:no_cache]
    end
  
    def base
      return -1 unless validate_authentication_options

      puts "Krawling..."

      if use_authentication?
        authenticate(@agent, @username, @password, @login_url)
      end

      crawl_page(@url, @agent)
      initialize_threads(@agent)
    
      puts "#{@crawled_links.size} total Good Links"
    
      puts "Bad Links:"
      @bad_links.each { |link| puts link }
    
      puts "Suspect Links:"
      @suspect_links.each { |link| puts link }
    end

    def initialize_threads(agent)
      @links_to_crawl = @links_to_crawl + ['/featured/Movies', '/featured/Kids','/featured/Networks','/featured/TV Series']

      threads = []
      @threads.times do |i|
        threads << Thread.new(i) do

          agent = @agent.dup

          while !@links_to_crawl.empty? do
            link = @mutex.synchronize {
              if @randomize
                @links_to_crawl.slice!(rand(@links_to_crawl.size))
              else
                @links_to_crawl.pop
              end
            }
            crawl_page(link, agent)
          end
        end
      end
      
      threads.each { |t| t.join }
    end
  
    def valid_xml?(xml_string)
      begin
        Nokogiri::XML(xml_string) { |config| config.options = Nokogiri::XML::ParseOptions::STRICT }
      rescue Nokogiri::XML::SyntaxError => e
        false
      end
    end

    def number_episodes_in_xml(xml_doc)
      xml_doc.xpath('//xbox:episode').length
    end

    def crawl_page(link, agent)
      
      @crawled_links << link
      num_episodes = 'not_series_xml'
      begin
        start = Time.now
        page = agent.get(link, [], nil, @headers)
      rescue Mechanize::ResponseCodeError => e
        @mutex.synchronize { puts e }
        error = e
        @bad_links << link
        return
      rescue Timeout::Error => e
        @suspect_links << link
        return
      ensure
        @mutex.synchronize do
          real = Time.now - start
          if page
            runtime = page.header['x-runtime'].to_f
            network = (real - runtime).round(10)
          else
            runtime = '0'
            network = '0'
          end
          if link.to_s.end_with?('xml')
            if doc = valid_xml?(page.body)
              if link.to_s.start_with?('/series')
                num_episodes = number_episodes_in_xml(doc)
                bad_xml_structure = true if num_episodes < 1
              end
            else
              puts "#{link} was badly formed XML"
            end
          end
          puts link.to_s
          if page.nil?
            puts error
          else
            puts "   #{page.response["status"]} #{'TOO LONG' if real > 10} #{'BADLY_STRUCTURED_XML' if bad_xml_structure} [#{real}s real] [#{runtime}s runtime] [#{network}s network] [#{num_episodes} episodes] #{@links_to_crawl.size} links..."
        end
      end
  
      @mutex.synchronize do
        return if !page.respond_to?(:links)

        #recache_invalid_results(page)

        page.links.each do |new_link|
          next if new_link.href.nil?
          next if new_link.rel.include? 'nofollow'
          
          # quick scrub known issues
          new_link = new_link.href.gsub(/ /, '%20')
  
          begin
            new_url = URI(new_link)
            new_link = new_url.to_s
          rescue ArgumentError # junk link
            next
          end

          if @domain || (new_link =~ /^#{Regexp.escape(@host)}/) || (new_link =~ /^\//) # don't crawl external domains
  
            next if @crawled_links.include?(new_link) || @links_to_crawl.include?(new_link) # don't crawl what we've alread crawled
            next if @exclude  && new_link =~ /#{@exclude}/   # don't crawl excluded matched paths

            if @restrict  # don't crawl outside of our restricted base path
              if @include && new_url.path =~ /#{@include}/ # unless we match our inclusion
                # ignore
              else
                if new_url.path !~ /^#{Regexp.escape(@base_path)}/
                  next
                end
              end
            end

            @links_to_crawl << new_link
          end
        end
      end
    end

    protected

    def params_to_hash(params)
      params = CGI.unescape(params)
      Hash[ params.split('&').map { |p| p.split('=') } ]
    end

    def hash_to_params(hash)
      hash.map { |k, v| "#{k}=#{v}" }.sort * '&'
    end

    def recache_invalid_results(page)
      page.search('tr td i.icon-remove').each do |invalid|
        a = invalid.parent.parent.css('a').first
        next if a.nil?
        uri = URI(a['href'])
        query = params_to_hash(uri.query || '')
        query['cache'] = 'false'
        uri.query = hash_to_params(query)
        if @restrict  # don't crawl outside of our restricted base path
          if @include && uri.path =~ /#{@include}/ # unless we match our inclusion
            if !@crawled_links.include?(uri.path) && !@links_to_crawl.include?(uri.path) # don't crawl what we've alread crawled
              @links_to_crawl << uri.to_s
            end
          end
        end
      end
    end
  end
end
