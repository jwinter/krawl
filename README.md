# Krawler

Simple little command-line web crawler.  Use it to find 404's or 500's on your site.
I use it to warm caches.  Multi-threaded enabled for faster crawling.

## Installation

Install:

    gem install krawler

## Usage

From the command line:

    $ krawl http://localhost:3000/

Options:

    -e, --exclude regex              Exclude matching paths
    -s, --sub-restrict               Restrict to sub paths of base url
    -c, --concurrent count           Crawl with count number of concurrent connections
    -r, --randomize                  Randomize crawl path

Examples:

Restrict crawling to sub-paths of /public

    $ krawl http://localhost:3000/public -s

Restrict crawling to paths that do not match `/^\/api\//`

    $ krawl http://localhost:3000/ -e "^\/api\/"

Crawl with 4 current threaded crawlers. Make sure your server is capable of handling
concurrent requests.

    $ krawl http://production.server -c 4

Randomize the crawl path.  Helpful when you have a lot of links and get bored watching
the same crawl path over and over.

    $ krawl http://localhost:3000/ -r


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
