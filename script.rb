class Script
  class << self
    def start
      anime_list = Hpricot(open('anime_list', 'r') { |f| f.read })
      puts "Anime list open"

      # Read in the URL to every series
      masterlist = []

      (anime_list/:li/:a).each do |series|
        anime = [series.inner_text, series[:href]]
        masterlist << anime
        puts "Built structure for #{anime.first}..."
      end

      puts

      puts "Fetched #{masterlist.size} animes. Now fetching episodes..."
      masterlist.each do |anime|
        puts "Fetching body (#{anime.first})"
        begin
          series = Anime.create!(title: anime.first)
          puts "Created new anime series"
        rescue
          series = Anime.find_by_title!(anime.first)
        end
        Scrape.new(anime.last, series.id).fetch
        puts "Snatched that bitch of Anime Goodness"
        puts
      end
    end

    def series
      anime_list = Hpricot(open('anime_list', 'r') { |f| f.read })
      puts "Anime list open"

      begin
        (anime_list/:li/:a).each do |series|
          anime = series.inner_text
          Anime.create!(title: anime)
          puts "Created #{anime}..."
        end
      rescue Exception => e
        puts "Skipping: #{e}"
      end
    end
  end

end

