RSpec.describe Swaffle::Api do
  let(:yaml_file) { File.expand_path("../fixtures/api/schema.yml", __dir__) }
  let(:json_file) { File.expand_path("../fixtures/api/schema.json", __dir__) }
  let(:api) { described_class.load_yaml_file(yaml_file) }

  describe "#definition" do
    subject { api.definition(name) }

    let(:name) { "User" }

    it "returns definition" do
      expect(subject.to_json).to be_json_including(type: "object", properties: { id: { description: "ID" } })
    end
  end

  describe "#path" do
    subject { api.path(path) }

    let(:path) { "/users/{id}" }

    it "returns path definition" do
      expect(subject.to_json).to be_json_including(get: { operationId: "getUser" })
    end
  end

  describe "#operation" do
    subject { api.operation(path, method) }

    let(:path) { "/users/{id}" }
    let(:method) { "get" }

    it "returns operation definition" do
      expect(subject.to_json).to be_json_including(parameters: [{ name: "id" }])
    end
  end

  describe "#response_schema" do
    subject { api.response_schema(path, method, status) }

    let(:path) { "/users/{id}" }
    let(:method) { "get" }
    let(:status) { 200 }

    it "returns response definition" do
      expect(subject.to_json).to be_json_including(description: "success")
    end
  end

  describe ".load_yaml_file" do
    subject { described_class.load_yaml_file(yaml_file) }

    it "is load definitions and paths" do
      expect(subject.definition("User").to_json).to be_json_including(type: "object")
    end
  end

  describe ".load_json_file" do
    subject { described_class.load_json_file(json_file) }

    it "is load definitions and paths" do
      expect(subject.definition("User").to_json).to be_json_including(type: "object")
    end
  end
end
