require "swaffle/spec/schema_matcher"

module Swaffle::Spec
  module ApiRequestHelper
    # リクエスト発行と、レスポンス検証を同時に行う
    %w[get post put patch delete].each do |method|
      # @param [Hash] json 本来のパラメータには存在しないが、jsonをrequest bodyに指定できるように追加
      # rubocop:disable Metrics/ParameterLists
      define_method("api_#{method}") do |path, params: nil, headers: nil, env: nil, xhr: false, as: nil, json: nil|
        headers = {} if headers.nil?
        headers.merge!(@headers) if @headers

        if json
          params = json.to_json
          headers.merge!({
            "HTTP_ACCEPT" => "application/json",
            "CONTENT_TYPE" => "application/json",
            "DATA_TYPE" => "json",
          })
        end
        send(method, eval_path(path), params: params, headers: headers, env: env, xhr: xhr, as: as)
        validate_response_schema(method, path, response)

        response
      end
      # rubocop:enable Metrics/ParameterLists
    end

    # レスポンス検証を行う
    # schemaとして定義されている内容か、を検証するのみで
    # 200などの成功系のレスポンスを保証するものではないので注意
    def validate_response_schema(method, path, response)
      expect([path, method, response]).to match_api_response_schema
    end

    # 呼び出し時のpathが「/foo/bar」などなっていると
    # 「/foo/{type}」のようなpath定義に一致しないため、
    # 「/foo/{type}」と書けば、{type}部分を展開してくれるように調整
    def eval_path(path)
      path.gsub(/{(\w+)}/) { send(Regexp.last_match(1)) }
    end
  end
end
