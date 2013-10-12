require 'spec_helper'
require 'dea/staging/buildpack_manager'

describe Dea::BuildpackManager do
  let(:base_dir) { Dir.mktmpdir }
  let(:admin_buildpacks_dir) { "#{base_dir}/admin_buildpacks" }
  let(:system_buildpacks_dir) { "#{base_dir}/system_buildpacks" }
  let(:admin_buildpacks) do
    [
      {
        "url" => "http://example.com/buildpacks/uri/abcdef",
        "key" => "abcdef"
      }
    ]
  end

  let(:buildpacks_in_use) { [] }

  after { FileUtils.rm_f(base_dir) }

  subject(:manager) { Dea::BuildpackManager.new(admin_buildpacks_dir, system_buildpacks_dir, admin_buildpacks, buildpacks_in_use) }

  def create_populated_directory(path)
    FileUtils.mkdir_p(File.join(path, "a_buildpack_file"))
  end

  describe "#download" do
    it "calls AdminBuildpackDownloader" do
      downloader_mock = mock(:downloader)
      downloader_mock.should_receive(:download)
      AdminBuildpackDownloader.should_receive(:new).with(admin_buildpacks, admin_buildpacks_dir) { downloader_mock }

      manager.download
    end
  end

  describe "#clean" do
    let(:file_to_delete) { File.join(admin_buildpacks_dir, "1234") }
    let(:file_to_keep) { File.join(admin_buildpacks_dir, "abcdef") }

    before do
      [file_to_delete, file_to_keep].each do |path|
        create_populated_directory path
      end
    end

    context "when there are no admin buildpacks in use" do
      it "cleans deleted admin buildpacks" do
        expect {
          manager.clean
        }.to change {
          File.exists? file_to_delete
        }.from(true).to(false)

        expect(File.exists? file_to_keep).to be_true
      end
    end

    context "when an admin buildpack is in use" do
      let(:buildpacks_in_use) { [{ "uri" => "foo", "key" => "efghi" }] }

      let(:file_in_use) {File.join(admin_buildpacks_dir, "efghi")}

      before do
        create_populated_directory(file_in_use)
      end

      it "that buildpack doesn't get deleted" do
        expect {
          manager.clean
        }.to change {
          File.exists? file_to_delete
        }.from(true).to(false)
        expect(File.exists? file_to_keep).to be_true
        expect(File.exists? file_in_use).to be_true
      end
    end
  end

  describe "#list" do
    let(:system_buildpack) { File.join(system_buildpacks_dir, "abcdef") }

    before do
      create_populated_directory(system_buildpack)
    end

    context "when there are admin buildpacks" do
      let(:admin_buildpacks) do
        [
          {
            "url" => "http://example.com/buildpacks/uri/admin",
            "key" => "admin"
          },
          {
            "url" => "http://example.com/buildpacks/uri/cant_find_admin",
            "key" => "cant_find_admin"
          }
        ]
      end

      let(:admin_buildpack) { File.join(admin_buildpacks_dir, "admin") }

      before { create_populated_directory(admin_buildpack) }

      it "has the correct number of buildpacks" do
        expect(manager.list).to have(2).item
      end

      it "copes with an admin buildpack not being there" do
        expect(manager.list).to include("#{admin_buildpacks_dir}/admin")
      end

      it "includes the admin buildpacks which is there" do
        expect(manager.list).to_not include("#{admin_buildpacks_dir}/cant_find_admin")
      end
    end

    context "when there are no admin buildpacks" do
      it "includes the system buildpacks" do
        expect(manager.list).to have(1).item
        expect(manager.list).to include("#{system_buildpacks_dir}/abcdef")
      end
    end
  end
end

__END__

describe StagingConfigFile do
  describe "#write" do
    it "includes the source dir of the warden container"
    it "includes the destination dir of where the staging will put its droplet"
    it "includes the cache dir where the builpack will put its cache"
    it "includes the environment (which includes the buildpack, buildpack url, buildpack key and start command)"
    it "includes the name of the file to put in the release info"

    context "when there are admin buildpacks" do
      it "includes the admin buildpacks in the correct order"
      it "includes the system buildpacks"
    end

    context "when there are no admin buildpacks" do
      it "includes the system buildpacks"
    end
  end
end
