require_relative "../fixtures/models/user"
require_relative "../fixtures/models/team"
require_relative "../fixtures/serializers/user_serializer"
require_relative "../fixtures/serializers/current_user_serializer"

RSpec.describe Swaffle::Serializer do
  let(:yaml_file) { File.expand_path("../fixtures/api/schema.yml", __dir__) }
  let(:now) { Time.now }
  let(:object) { User.new(id: "a", nickname: "KIUCHI Satoshinosuke", last_logined_at: now) }
  let(:serialized) { serializer.new(object) }
  let(:serializer) { described_class }

  before do
    Swaffle.load(yaml_file)
  end

  describe "#definition_name" do
    subject { serialized.definition_name }

    it { is_expected.to eq "User" }

    context "custom serializer" do
      let(:serializer) { CurrentUserSerializer }

      it { is_expected.to eq "CurrentUser" }
    end
  end

  describe "#definition" do
    subject { serialized.definition }

    it "gets definition from api" do
      expect(subject).to be_a Swagger::Data::Schema
      expect(subject.properties.to_json).to be_json_including({ nickname: { type: "string" } })
    end
  end

  describe "#as_json" do
    subject { serialized.as_json }

    it do
      expect(subject).to include("id" => "a", "nickname" => "KIUCHI Satoshinosuke")
    end
  end

  describe ".find_serializer" do
    subject { described_class.find_serializer(object) }

    it { is_expected.to be_a UserSerializer }

    context "specify serializer" do
      subject { described_class.find_serializer(object, CurrentUserSerializer) }

      it { is_expected.to be_a CurrentUserSerializer }
    end
  end
end
