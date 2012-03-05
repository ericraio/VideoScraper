require 'mechanize'

$mech = Mechanize.new
$mech.user_agent_alias = 'Mac Safari'


class Scrape

  def initialize(url, id)
    @mech = $mech.get(url)
    @anime_id = id
  end

  def fetch
    page = @mech
    links = page.links
    fetch_episodes(page, links)
  end

  def fetch_animes(page)
    desc = page.search('.catdescription').text
    image = page.search('.catdescription img').to_s
    title = page.uri.to_s.match(/category\/(.*)\//)

    Anime.create!(description: desc, image_url: image, title: title)
  end

  def fetch_episodes(start_page, links)
    links.each do |link|
      begin
        page = link.click
        title = page.search('h1').text
        video = page.search('p embed').to_s
        unless video.empty?
          begin
            episode = Episode.create!(title: title, embed_url: video, anime_id: @anime_id)
            puts "Saved " + episode.title
          rescue
            episode = Episode.find_by_title(title)
            if episode.anime_id.nil?
              episode.update_attributes(anime_id: @anime_id)
              puts "Updated Episode:" + title
            end
          end
        end
      rescue Exception => e
        puts "Skipping: #{e}"
      end
    end

    if start_page.link_with(:text => 'Next').nil?
      puts "Skipping New Page"
    else
      next_page = start_page.link_with(:text => 'Next').click
      next_links = next_page.links
      fetch_episodes(next_page, next_links) 
      puts "Switched to New Page"
    end
  end

end
