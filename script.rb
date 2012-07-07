class Script
  class << self
    def start
      anime_list = Hpricot(open('anime_list', 'r') { |f| f.read })
      masterlist = []

      (anime_list/:li/:a).each do |series|
        anime = [series.inner_text, series[:href]]
        masterlist << anime
        puts "Built structure for #{anime.first}..."
      end

      puts "Fetched #{masterlist.size} animes. Now fetching episodes..."
      masterlist.each do |anime|
        begin
          puts "Fetching body (#{anime.first})"
          series = Anime.create!(title: anime.first)
        rescue
          series = Anime.find_by_title!(anime.first)
        end
        Scrape.new(anime.last, series.id).fetch
        puts "Snatched that bitch of Anime Goodness\n"
      end
    end

    def series
      anime_list = Hpricot(open('anime_list', 'r') { |f| f.read })

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

