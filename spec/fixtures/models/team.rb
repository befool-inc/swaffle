require "active_record"

class Team
  include ActiveModel::Model

  attr_accessor :id, :name
end
