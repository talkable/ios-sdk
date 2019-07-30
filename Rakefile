require 'aws-sdk'

CONFIGURATION   = 'Release'
BUILD_DIR       = 'build'
PROJECT_NAME    = 'TalkableSDK'
UNIVERSAL_SDK   = "#{BUILD_DIR}/#{CONFIGURATION}-universal/#{PROJECT_NAME}.framework/#{PROJECT_NAME}"
TMP_DIR         = 'tmp'
DEMO_DIR        = 'example/TalkableSDKDemo'
SDK_ARCHIVE     = "#{BUILD_DIR}/talkable_ios_sdk.zip"

AWS_KEY         = 'AKIAJO2XLL4WTAL3QLRQ'
AWS_SECRET      = 'XrQxWEitMUCCNeFrhH8mPoYeIXZiDGTIDkUtO/EF'
AWS_REGION      = 'us-east-1'
AWS_CREDENTIALS = Aws::Credentials.new(AWS_KEY, AWS_SECRET)
AWS_BUCKET_NAME = 'talkable-downloads'

module Rake
  module DSL
    def run(command)
      puts "> #{command}"
      system(command)
      fail "Command `#{command}` failed with exit status #{$?}" unless $?.success?
    end

    def version
      @version ||= `agvtool what-version -terse`.strip
    end

    def zip_compress(archive_name, dir)
      # Clean up
      FileUtils.rm_rf(TMP_DIR)

      FileUtils.mkdir_p(TMP_DIR)
      FileUtils.cp_r(dir, TMP_DIR)

      filename = "#{archive_name}.zip"

      run "cd #{TMP_DIR} && zip -r #{filename} ./*"
      File.join(TMP_DIR, filename)
    end

    def s3(source, destination)
      puts "  S3: #{source} => #{destination}"

      @bucket ||= Aws::S3::Resource.new(
        region: AWS_REGION,
        credentials: AWS_CREDENTIALS
      ).bucket(AWS_BUCKET_NAME)

      cache_period = 86400
      options = {acl: 'public-read',
                 content_type: 'application/zip',
                 cache_control: "max-age=#{cache_period}, public",
                 expires: Time.at(Time.now.to_i + cache_period)}
      object = @bucket.object(destination)
      object.upload_file(source, options)
      object.public_url.to_s
    end
  end
end


task default: :build

task :check_master do
  branch = `git rev-parse --abbrev-ref HEAD`.strip
  abort('Deploy can be only done from `master` branch') unless branch == 'master'

  any_changes = `git status --porcelain 2>/dev/null | wc -l`.strip != '0'
  abort('Please commit or stash all your changes before deploy') if any_changes

  last_origin_commit = `git ls-remote origin master`.split(/\s/)[0].strip
  last_local_commit = `git rev-parse HEAD`.strip
  abort('Pull all changes from master before deploy') unless last_origin_commit == last_local_commit
end

task :check_version do
  tag_present = `git tag -l v#{version}`.strip != ''
  abort("Tag for version #{version} already exists. Please bump version and run task again.") if tag_present
end

task :build do
  run "xcodebuild ONLY_ACTIVE_ARCH=NO -configuration #{CONFIGURATION} -sdk iphoneos clean build"
  run "xcodebuild ONLY_ACTIVE_ARCH=NO -configuration #{CONFIGURATION} -sdk iphonesimulator VALID_ARCHS='i386 x86_64' build"
end

task lipo: :build do
  builds = %w(iphoneos iphonesimulator).map do |sdk|
    File.join(BUILD_DIR, "#{CONFIGURATION}-#{sdk}", "#{PROJECT_NAME}.framework", PROJECT_NAME)
  end

  # Clean up
  FileUtils.rm_rf(UNIVERSAL_SDK)

  # Create file structure
  FileUtils.mkdir_p(File.dirname(UNIVERSAL_SDK))
  FileUtils.cp_r(File.dirname(builds.first), File.dirname(File.dirname(UNIVERSAL_SDK)))

  # Join frameworks
  run "lipo -create #{builds.join(' ')} -output #{UNIVERSAL_SDK}"
end

task compress: :lipo do
  archive_path = zip_compress('talkable_ios_sdk', File.dirname(UNIVERSAL_SDK))
  FileUtils.cp_r(archive_path, SDK_ARCHIVE)
end

desc 'Build and Archive framework'
task archive: :compress do
  puts '*'*20
  puts SDK_ARCHIVE
  puts '*'*20
end

desc 'Deploy framework to Amazone S3'
task deploy: :compress do
  puts s3(SDK_ARCHIVE, "ios-sdk/talkable_ios_sdk_#{version}.zip")
  puts s3(SDK_ARCHIVE, "ios-sdk/talkable_ios_sdk.zip")
end

task :tag do
  run "git tag v#{version}"
  run "git push origin master:master --tags"
end

desc 'Release new SDK version'
task release: [:check_master, :check_version, :deploy, :tag]

desc 'Upload Demo Example'
task :demo do
  archive_path = zip_compress('talkable_sdk_demo', DEMO_DIR)
  puts s3(archive_path, "ios-sdk/talkable_sdk_demo.zip")
end
