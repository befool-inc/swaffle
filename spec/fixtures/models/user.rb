require "active_record"

class User
  include ActiveModel::Model

  attr_accessor :id, :nickname, :last_logined_at
end
