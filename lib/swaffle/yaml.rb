require "json"
require "yaml"
require "erb"

module Swaffle
  module Yaml
    def self.read_yaml_file(file_path)
      YAML.safe_load(ERB.new(::IO.read(file_path)).result)
    end

    def self.load_file_with_ref(path, root)
      hash = read_yaml_file(path)
      resolved_hash = load_ref_with_file(hash, path, root)
      # 200 みたいな int の key を string にしたい
      JSON.parse(resolved_hash.to_json)
    end

    # file が対象の $ref を置き換える
    #
    #   $ref: ./UserApp.yml
    #
    # これ以上複雑化するようであればリファクタリングする
    def self.load_ref_with_file(node, path, root)
      case node
      when Hash
        if node.key?("$ref") && !node["$ref"].start_with?("#/")
          target_file = resolve_file_path(node["$ref"], path, root)
          load_file_with_ref(target_file, root)
        elsif node.key?("$merge") && !node["$merge"].start_with?("#/")
          target_file = resolve_file_path(node["$merge"], path, root)
          hash = load_file_with_ref(target_file, root)

          if node.count > 1
            remains = node.to_a.reject { |k, _| k == "$merge" }
            remain_hash = remains.map { |k, v| [k, load_ref_with_file(v, path, root)] }.to_h
            hash = hash.deep_merge(remain_hash)
          end

          hash
        else
          node.map { |k, v| [k, load_ref_with_file(v, path, root)] }.to_h
        end
      when Array
        node.map { |e| load_ref_with_file(e, path, root) }
      else
        node
      end
    end

    # JSON path が対象の $ref を置き換える
    #
    #   $ref: '#/definitions/User'
    def self.load_ref_with_path(node, root, resolve_ref)
      case node
      when Hash
        if node.key?("$ref") && node["$ref"].start_with?("#/")
          load_ref_with_path_for_ref(node, root, resolve_ref)
        elsif node.key?("$merge") && node["$merge"].start_with?("#/")
          load_ref_with_path_for_merge(node, root, resolve_ref)
        else
          node.map { |k, v| [k, load_ref_with_path(v, root, resolve_ref)] }.to_h
        end
      when Array
        node.map { |e| load_ref_with_path(e, root, resolve_ref) }
      else
        node
      end
    end

    def self.load_ref_with_path_for_ref(node, root, resolve_ref)
      if resolve_ref
        path = node["$ref"].sub(%r{^#/}, "").split("/")
        definition = root.dig(*path)
        load_ref_with_path(definition, root, resolve_ref)
      else
        node
      end
    end

    def self.load_ref_with_path_for_merge(node, root, resolve_ref)
      path = node["$merge"].sub(%r{^#/}, "").split("/")
      definition = root.dig(*path)
      hash = load_ref_with_path(definition, root, resolve_ref)

      if node.count > 1
        remains = node.to_a.reject { |k, _| k == "$merge" }
        remain_hash = remains.map { |k, v| [k, load_ref_with_path(v, root, resolve_ref)] }.to_h
        hash = hash.deep_merge(remain_hash)
      end

      hash
    end

    # ファイルパスを解決する
    #
    # - ./foo/bar/zoo: 相対パス: パース中のファイルを起点にパス解決する
    # - ~/foo/bar/zoo: 絶対パス: ルートファイルを起点にパス解決する
    def self.resolve_file_path(ref, path, root)
      if ref.start_with?("~/")
        File.expand_path(ref.gsub(/^~/, "."), root)
      else
        File.expand_path(ref, File.dirname(path))
      end
    end

    # デフォルトでrequiredとし、オプショナルなカラムはプロパティにoptional: trueをつけて指定するようにする
    def self.convert_default_required(node)
      case node
      when Hash
        # type: object かつ、propertiesが存在し、required指定が存在しない場合、
        # プロパティにoptional: trueがなければrequiredとして扱う。
        if node["type"] == "object" && !node.key?("required") && node["properties"]
          required_keys = []
          node["properties"].each do |k, v|
            required_keys << k unless v["optional"]
          end
          node["required"] = required_keys
        end
        Hash[node.map { |k, v| [k, convert_default_required(v)] }]
      when Array
        node.map { |e| convert_default_required(e) }
      else
        node
      end
    end

    # パスのところでsummaryが省略されている場合はdescriptionから補完
    def self.convert_paths_summary(node)
      case node
      when Hash
        node["summary"] = node["description"] || "" if node.key?("operationId") && !node.key?("summary")
        Hash[node.map { |k, v| [k, convert_paths_summary(v)] }]
      when Array
        node.map { |e| convert_default_required(e) }
      else
        node
      end
    end

    # resolve_mode
    #   :never
    #     何も解決しない
    #   :file
    #     $ref(file) のみ解決する
    #   :all
    #     $ref(file), $ref(JSON path) の両方を解決する
    def self.load(path, resolve_mode)
      hash = case resolve_mode
             when :never
               # Hash 化して
               tmp = JSON.parse(YAML.load_file(path).to_json)
               # $merge(JSON path) のみ解決する
               load_ref_with_path(tmp, tmp, false)
             when :file
               # $ref(file) を解決しながら一度 Hash 化する
               tmp = load_file_with_ref(path, File.dirname(path))
               # $merge(JSON path) のみ解決する
               load_ref_with_path(tmp, tmp, false)
             when :all
               # $ref(file) を解決しながら一度 Hash 化する
               tmp = load_file_with_ref(path, File.dirname(path))
               # $ref(JSON path), $merge(JSON path) を解決する
               load_ref_with_path(tmp, tmp, true)
             end
      convert_default_required(hash)
      convert_paths_summary(hash)
    end
  end
end
