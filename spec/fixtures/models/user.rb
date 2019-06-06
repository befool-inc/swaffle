class User < ActiveRecord::Base
  belongs_to :team
  belongs_to :belong, polymorphic: true
end
