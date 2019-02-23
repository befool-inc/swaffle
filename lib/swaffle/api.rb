require "ruby-swagger"

module Swaffle
  class Api
    def initialize(hash)
      @data = Swagger::Data::Document.parse(hash)
    end

    def definition(name)
      raise ArgumentError, "no such definition. #{name}" unless @data.definitions[name]

      @data.definitions[name]
    end

    def path(name)
      raise ArgumentError, "no such path. #{name}" unless @data.paths[name]

      @data.paths[name]
    end

    def operation(path, method)
      operation = self.path(path).send(method)
      raise ArgumentError, "no such operation. #{method} #{path}" unless operation

      operation
    end

    def response_schema(path, method, status)
      operation = operation(path, method)
      response = operation.responses[status.to_s]
      raise ArgumentError, "no such response. #{method} #{path} #{status}" unless response

      response
    end

    def self.load_json_file(json_file)
      raise ArgumentError, "no such json file. #{json_file}" unless File.exist?(json_file)

      load_hash(JSON.parse(File.read(json_file)))
    end

    def self.load_yaml_file(yaml_file, mode: :all)
      raise ArgumentError, "no such yaml file. #{yaml_file}" unless File.exist?(yaml_file)

      load_hash(Swaffle::Yaml.load(yaml_file, mode))
    end

    def self.load_hash(hash)
      Api.new(hash)
    end
  end
end
