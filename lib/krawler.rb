require 'krawler/version'
require 'mechanize'
require 'timeout'
require 'uri'
require 'thread'

module Krawler

  class Base

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
      @randomize        = options[:randomize]
      @threads          = options[:threads]   || 1
      @username         = options[:username]
      @password         = options[:password]
      @login_url        = options[:login_url]
      @mutex            = Mutex.new
      @agent            = Mechanize.new
      @agent.user_agent = 'Krawler'
      @agent.ssl_version = 'SSLv3'
      @headers          = { 'Accept-Encoding' => 'gzip, deflate' }
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

    def authenticate(agent, user, password, login_url)
      agent.get(login_url) do |page|
        login_form = page.form

        login_form['user[email]'] = user
        login_form['user[password]'] = password

        agent.submit(login_form, login_form.buttons.first)
      end
    end

    def use_authentication?
      !@username.nil? || !@password.nil? || !@login_url.nil?
    end

    def validate_authentication_options
      any_nil = [@login_url, @username, @password].any? {|v| v.nil?}
      all_nil = [@login_url, @username, @password].all? {|v| v.nil?}
      if (any_nil && !all_nil)
        puts "You must either provide all authentication options" +
          " (username, password, and loginurl) or provide none."
        return false
      else
        return true
      end
    end

    def initialize_threads(agent)
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
  
    def crawl_page(link, agent)
      
      @crawled_links << link

      begin
        start = Time.now
        page = agent.get(link, [], nil, @headers)
      rescue Mechanize::ResponseCodeError => e
        @mutex.synchronize { puts e }
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
          puts link
          puts "    [#{real}s real] [#{runtime}s runtime] [#{network}s network] #{@links_to_crawl.size} links..."
        end
      end
  
      @mutex.synchronize do
        return if !page.respond_to?(:links)
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
  
          if (new_link =~ /^#{Regexp.escape(@host)}/) || (new_link =~ /^\//) # don't crawl external domains
  
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
  end
end
