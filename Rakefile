CONFIGURATION   = 'Release'
BUILD_DIR       = 'build'
PROJECT_NAME    = 'TalkableSDK'
UNIVERSAL_SDK   = "#{BUILD_DIR}/#{CONFIGURATION}-universal/#{PROJECT_NAME}.framework/#{PROJECT_NAME}"
TMP_DIR         = 'tmp'
SDK_ARCHIVE     = "#{BUILD_DIR}/talkable_ios_sdk.zip"

module Rake
  module DSL
    def run(command)
      puts "> #{command}"
      system(command)
      fail "Command `#{command}` failed with exit status #{$?}" unless $?.success?
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
  end
end

task default: :build

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
