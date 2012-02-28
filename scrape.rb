require 'rubygems'
require 'mechanize'
require 'highline/import'
require 'hpricot'
require 'yaml'
HighLine.track_eof = false

$mech = Mechanize.new
$mech.user_agent_alias = 'Mac Safari'

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

def fetch(url)
  links = $mech.get(url).links
  links.each do |link|
    begin
      page = link.click
      title = page.search('h1')
      video = page.search('embed')
    rescue
      # Skip if the link has no video
      nil
    end
  end
end

def getPage(url)
  puts "Not stored in db. Fetching from site..."
  fetch(url)
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

main
