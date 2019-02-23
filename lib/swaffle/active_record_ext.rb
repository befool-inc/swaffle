module Swaffle
  module ActiveRecordExt
    extend ActiveSupport::Concern

    def serializer(*args)
      Swaffle::Serializer.find_serializer(self, *args)
    end
  end
end
