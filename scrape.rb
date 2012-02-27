require 'rubygems'
require 'hpricot'
require 'mechanize'
require 'tempfile'
require 'highline/import'
require 'yaml'
HighLine.track_eof = false

$mech = Mechanize.new
$mech.user_agent_alias = 'Mac Safari'

###############################
$skip_until = false
###############################

def puts2(txt='')
  puts "*** #{txt}"
end

#  Anime has: title, type (series, movie), series
#  Episode has name/#, description, parts (video code)

class Episode
  attr_accessor :name, :src, :desc, :cover
  def initialize(title, page)
    @src = page # parts (megavideo, youtube etc)
    @name = title
    @desc = nil # episode description
    @cover = nil # file path
  end
end

class Anime
  attr_accessor :name, :page, :completed, :anime_type, :episodes
  def initialize(title, page)
    @name = title
    @page = page
    @episodes = []
    @anime_type = 'series'
    @completed = false
  end

  def complete!
    @completed = true
  end

  def episode!(episode)
    @episodes << episode
  end
end

class Cache
  def initialize
    # Setup physical cache location
    @path = 'cache'
    Dir.mkdir @path unless File.exists?(@path)

    # key/val = url/filename (of fetched data)
    @datafile = "#{@path}/cache.data"
    @cache = load(@datafile)
  end

  def put(key, val)
    tf = Tempfile.new('gogoanime', @path)
    path = tf.path
    tf.close! # important!

    puts2 "Saving to cache (#{path})"
    open(path, 'w') { |f|
      f.write(val)
      @cache[key] = path
    }

    save(@datafile)
  end

  def get(key)
    return nil unless exists?(key) && File.exists?(@cache[key])
    open(@cache[key], 'r') { |f| f.read }
  end

  def exists?(key)
    @cache.has_key?(key) 
  end

private
  # Load saved cache
  def load(file)
    return File.exists?(file) ? YAML.load(open(file).read) : {}
  end

  # Save cache
  def save(path)
    open(path, 'w') { |f|
      f.write @cache.to_yaml
    }
  end
end

$cache = Cache.new

def fetch(url)
  links = $mech.get(url).links
  links.each do |link|
    begin
      page = link.click
      title = page.search('h1') 
      video = page.search('p embed')
      post = title + video
      $cache.put(link, post) unless video.empty?
    rescue
      # Skip if the link has no video
      nil
    end
  end
end

def getPage(url)
  # First let's see if this is cached already
  body = $cache.get(url) 

  if body.nil?
    puts "Not cached. Fetching from site..."
    body = fetch(url)
  end
  body
end

def main
  anime_list = Hpricot(open('anime_list', 'r') { |f| f.read })
  puts2 "Anime list open"

  # Read in the URL to every series
  masterlist = []

  (anime_list/:li/:a).each do |series|
    anime = Anime.new(series.inner_text, series[:href])
    masterlist << anime
    puts2 "Built structure for #{anime.name}..."
  end

  puts2

  puts2 "Fetched #{masterlist.size} animes. Now fetching episodes..."
  masterlist.each do |anime|
    puts2 "Fetching body (#{anime.name})"
    body = getPage(anime.page)
    puts2 "Snatched that bitch (#{body.size} bytes of Anime Goodness)"
    puts2

    anime.complete!
    # XXX save the entire anime object, instead of just cache
  end
end

def inTitle(document, title)
  return (document/:title).inner_text[title]
end

def inUrl(url, part)
  return url[part]
end

def single_episode?(name)
  !(name =~ /[0-9] ?([+&]|and) ?[0-9]/)
end

def clean(txt)
  # This picks up most of them, but some are missing. Like *Final* and just plain "Final"
  txt[' (Final)']='' if txt[' (Final)']
  txt[' (Final Episode)']='' if txt[' (Final Episode)']
  txt[' (FINAL)']='' if txt[' (FINAL)']
  txt[' (FINAL EPISODE)']='' if txt[' (FINAL EPISODE)']

  txt['(Final)']='' if txt['(Final)']
  txt['(Final Episode)']='' if txt['(Final Episode)']
  txt['(FINAL)']='' if txt[' (FINAL)']
  txt['(FINAL EPISODE)']='' if txt[' (FINAL EPISODE)']

  txt
end

main
