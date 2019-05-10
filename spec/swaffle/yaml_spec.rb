RSpec.describe Swaffle::Yaml do
  let(:file) { File.expand_path("../fixtures/api/schema.yml", __dir__) }

  describe ".load" do
    subject { Swaffle::Yaml.load(file, mode) }

    context "mode all" do
      let(:mode) { :all }

      it "is parse fully" do
        expect(subject.to_json).to be_json_including({
          "swagger" => "2.0",
          "definitions" => {
            "User" => {
              "type" => "object",
            },
          },
          "paths" => {
            "/users/{id}" => {
              "get" => {
                "operationId" => "getUser",
                "responses" => {
                  "200" => {
                    "schema" => {
                      "properties" => {
                        "user" => {
                          "type" => "object",
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        })

        expect(subject["definitions"]["User"]["required"]).not_to include("team")
      end
    end

    context "mode file" do
      let(:mode) { :file }

      it "is parse only file path" do
        expect(subject.to_json).to be_json_including({
          "swagger" => "2.0",
          "definitions" => {
            "User" => {
              "type" => "object",
            },
          },
          "paths" => {
            "/users/{id}" => {
              "get" => {
                "operationId" => "getUser",
                "responses" => {
                  "200" => {
                    "schema" => {
                      "properties" => {
                        "user" => {
                          "$ref" => "#/definitions/User",
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        })

        expect(subject["definitions"]["User"]["required"]).not_to include("team")
      end
    end

    context "mode never" do
      let(:mode) { :never }

      it "is never parse" do
        expect(subject.to_json).to be_json_including({
          "swagger" => "2.0",
          "definitions" => {
            "$ref" => "./definitions/index.yml",
          },
          "paths" => {
            "$ref" => "./paths/index.yml",
          },
        })
      end
    end
  end
end
