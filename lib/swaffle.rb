require "swaffle/version"
require "swaffle/api"
require "swaffle/yaml"
require "swaffle/serializer"

module Swaffle
  @schemata = {}
  @current_key = nil

  class Error < StandardError; end

  module_function

  # Swaffle::Api.load_*_file へのブリッジ
  def load(file, format: :yaml, mode: :all, key: "@")
    api = case format
          when :yaml
            Api.load_yaml_file(file, mode: mode)
          when :json
            Api.load_json_file(file)
          else
            raise Error, "invalid format. use yaml or json."
          end
    @schemata[key] = api
    @current_key ||= key # rubocop:disable Naming/MemoizedInstanceVariableName
  end

  def get(key = "@")
    @schemata[key]
  end

  def current=(key)
    @current_key = key
  end

  def current
    get(@current_key)
  end
end
