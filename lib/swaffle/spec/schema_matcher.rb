require "json-schema"

# レスポンスのスキーマ検証
RSpec::Matchers.define :match_api_response_schema do # rubocop:disable Metrics/BlockLength
  match do |(path, method, response)|
    swagger = Swaffle.current

    # operation
    @operation = swagger.operation(path, method)
    return false unless @operation

    # content types
    @produces = @operation.produces
    return false unless @produces.include?(response.content_type)

    # status code
    @responses = @operation.responses

    case response.status
    when 500
      # 500系はそもそもテスト失敗
      return false

    else
      return false unless @responses[response.status.to_s]

      schema = swagger.response_schema(path, method, response.status).schema
    end

    @schema = schema.as_swagger
    @schema = resolve_nullable(@schema)
    JSON::Validator.validate(@schema.as_json, response.parsed_body)
  end

  failure_message do |(path, method, response)|
    base = "\n#{response.body}"
    return "has happened something error." + base if response.status >= 500
    return "expected has operation '#{method} #{path}', but not found." + base unless @operation
    unless @produces.include?(response.content_type)
      return "expected has produce in '#{@produces.join(",")}', but not found." + base
    end
    return "expected has response schema '#{method} #{path} (status:#{response.status})', but not found." + base unless @schema

    actual = response.parsed_body
    expected = resolve_diffable(@schema, actual)

    message = "expected that #{actual} would match #{expected}.\n"
    message += "Diff:"
    message += differ.diff(actual, expected)
    message
  end

  def differ
    RSpec::Support::Differ.new(
      object_preparer: ->(object) { RSpec::Matchers::Composable.surface_descriptions_in(object) },
      color: RSpec::Matchers.configuration.color?,
    )
  end

  # schema定義に沿って、違う箇所をあぶり出し、diff表示しやすいようにする
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def resolve_diffable(schema, actual)
    return nil if schema.nil?

    type = schema["type"].is_a?(Array) ? schema["type"].first : schema["type"]

    # スキーマに一致しているならそのまま
    return actual if JSON::Validator.validate(schema, actual, { parse_data: false })

    case type
    when "object"
      expected = {}
      schema["properties"].each do |key, child_schema|
        expected[key] = resolve_diffable(child_schema, actual.is_a?(Hash) ? actual[key] : nil)
      end
    when "array"
      expected = []
      if actual.is_a?(Array)
        actual.each_with_index do |child_actual, index|
          expected[index] = resolve_diffable(schema["items"], child_actual)
        end
      else
        expected.push(resolve_diffable(schema["items"], nil))
      end
    when "integer"
      expected = 1
    when "number"
      expected = if schema["format"] == "float" || schema["format"] == "double"
                   1.0
                 else
                   1
                 end
    when "string"
      expected = "some string"
    when "boolean"
      expected = !actual
    end

    expected
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  # swaggerとjson-schemaでnullableの表現方法が違うので、ここで吸収する
  def resolve_nullable(schema)
    return schema if schema.nil?

    type = schema["type"]

    schema["type"] = [type, "null"] if schema["nullable"]

    case type
    when "object"
      schema["properties"] = schema["properties"].map { |key, property| [key, resolve_nullable(property)] }.to_h
    when "array"
      schema["items"] = resolve_nullable(schema["items"])
    end

    schema
  end
end
