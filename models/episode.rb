class Episode < ActiveRecord::Base
  validates_uniqueness_of :title
end
