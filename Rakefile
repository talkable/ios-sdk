BUILD_DIR       = 'build'
PROJECT_NAME    = 'TalkableSDK'
TMP_DIR         = 'tmp'
SDK_ARCHIVE     = "#{BUILD_DIR}/talkable_ios_sdk.zip"
FRAMEWORK_PATH        = "#{BUILD_DIR}/#{PROJECT_NAME}.xcframework"
IOS_ARCHIVE_PATH       = "#{BUILD_DIR}/iphoneos.xcarchive"
SIMULATOR_ARCHIVE_PATH = "#{BUILD_DIR}/iphonesimulator.xcarchive"
CATALYST_ARCHIVE_PATH  = "#{BUILD_DIR}/catalyst.xcarchive"

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
  FileUtils.rm_rf(BUILD_DIR)
  FileUtils.mkdir_p(BUILD_DIR)

  common = "-scheme #{PROJECT_NAME} BUILD_LIBRARIES_FOR_DISTRIBUTION=YES SKIP_INSTALL=NO"

  run "xcodebuild archive ONLY_ACTIVE_ARCH=NO #{common} -archivePath #{IOS_ARCHIVE_PATH} -sdk iphoneos clean"
  run "xcodebuild archive VALID_ARCHS='i386 x86_64 arm64' #{common} -archivePath #{SIMULATOR_ARCHIVE_PATH} -sdk iphonesimulator"
  run "xcodebuild archive #{common} -archivePath #{CATALYST_ARCHIVE_PATH} -destination='generic/platform=macOS,variant=Mac Catalyst,name=Any Mac'"
end

task framework: :build do
  # Clean up
  FileUtils.rm_rf(FRAMEWORK_PATH)

  # Create XCFramework
  frameworks = [IOS_ARCHIVE_PATH, SIMULATOR_ARCHIVE_PATH, CATALYST_ARCHIVE_PATH].map do |arch_path|
    framework_path = File.join(arch_path, "/Products/Library/Frameworks/#{PROJECT_NAME}.framework")
    "-framework #{framework_path}"
  end.join(' ')

  run "xcodebuild -create-xcframework #{frameworks} -output #{FRAMEWORK_PATH}"
end

task compress: :framework do
  archive_path = zip_compress('talkable_ios_sdk', FRAMEWORK_PATH)
  FileUtils.cp_r(archive_path, SDK_ARCHIVE)
end

desc 'Build and Archive framework'
task archive: :compress do
  puts '*'*20
  puts SDK_ARCHIVE
  puts '*'*20
end
