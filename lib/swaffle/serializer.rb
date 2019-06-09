require "ruby-swagger"

module Swaffle
  class Serializer
    attr_reader :object, :api

    def initialize(object, api: nil)
      @object = object
      @api = api || Swaffle.current
    end

    def definition_name
      if self.class == Swaffle::Serializer
        object.class.name
      else
        self.class.name.gsub(/Serializer$/, "")
      end
    end

    def definition
      api.definition(definition_name)
    end

    def has_enum?(col_name)
      object.is_a?(ActiveRecord::Base) && object.class.defined_enums.key?(col_name.to_s)
    end

    def method_missing(method, *args)
      if object.respond_to?(method)
        object.send(method, *args)
      else
        super
      end
    end

    def respond_to_missing?(symbol, _include_private = false)
      object&.respond_to?(symbol)
    end

    def as_json(_state = nil)
      Swaffle::Serializer.serialize(self, definition)
    end

    # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    def self.serialize(object, definition)
      definition = Swagger::Data::Schema.parse(definition) unless definition.is_a?(Swagger::Data::Schema)

      case definition.type
      when "array"
        # nullable: true の場合は nil が渡される可能性がある
        if object.is_a?(Enumerable)
          object.map { |o| serialize(o, definition.items) }
        else
          object
        end
      when "object"
        case object
        when nil, ::String, ::Numeric, ::Array
          object
        when ActiveRecord::Base
          serialize(find_serializer(object), definition)
        else
          definition.properties
                    .map { |key, schema| [key, serialize(get_value(object, key), schema)] }
                    .to_h
                    .reject { |key, value| value.nil? && !definition.required.include?(key) }
        end
      when "string"
        object&.to_s
      when "number"
        if definition.format == "float" || definition.format == "double"
          object&.to_f
        else
          object&.to_i
        end
      when "integer"
        object&.to_i
      else
        case object
        when ActiveRecord::Base
          find_serializer(object).as_json
        else
          object
        end
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity

    def self.get_value(object, key)
      value = if object.nil?
                nil
              elsif object.is_a?(Hash)
                object[key] || object[key.to_sym]
              else
                object.public_send(key)
              end

      # 日付系はRFC3339形式に
      # MEMO: RFC3339はswaggerのdate-formatで標準的なフォーマット
      value = value.rfc3339 if key.match?(/\A.*_at\z/) && !value.nil?

      value
    end

    # モデルから該当のserializerを探す
    def self.find_serializer(object, serializer_class = nil, *args)
      # serializer の指定がない場合
      unless serializer_class&.is_a?(Class) && serializer_class&.<=(Swaffle::Serializer)
        args.unshift(serializer_class) unless serializer_class.nil?
        serializer_class = nil
      end

      serializer_klass = serializer_class || "#{object.class.name}Serializer".safe_constantize || self

      serializer_klass.new(object, *args)
    end
  end
end
