require "swaffle/version"
require "swaffle/api"
require "swaffle/yaml"
require "swaffle/serializer"

module Swaffle
  class Error < StandardError; end

  module_function

  # Swaffle::Api.load_*_file へのブリッジ
  def load(file, format: :yaml, mode: :all, key: "@")
    case format
    when :yaml
      Api.load_yaml_file(file, mode: mode, key: key)
    when :json
      Api.load_json_file(file, key: key)
    else
      raise Error, "invalid format. use yaml or json."
    end
  end
end
