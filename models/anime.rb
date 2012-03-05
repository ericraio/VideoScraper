class Anime < ActiveRecord::Base
  validates_uniqueness_of :title
end
