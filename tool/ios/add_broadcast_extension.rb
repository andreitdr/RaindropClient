#!/usr/bin/env ruby
# Adds the RaindropBroadcast target — the Broadcast Upload Extension that hands
# this device's screen to the app while it shares it into a call — to
# ios/Runner.xcodeproj, and wires Runner up to embed it.
#
# The project file it edits is committed, so this does not run as part of any
# build. It is here because that file is not something to edit by hand, and
# because it is the record of exactly what the extension needed: run it again
# after anything regenerates the Xcode project (it changes nothing when the
# target is already there). The sources it points at are in
# ios/RaindropBroadcast/ and ios/Runner/Runner.entitlements.
#
# It needs the `xcodeproj` gem, which CocoaPods already brings:
#
#   GEM_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v pod)" || command -v pod)")")/libexec" \
#     ruby tool/ios/add_broadcast_extension.rb
#
# or simply, with Homebrew's CocoaPods:
#
#   GEM_HOME="$(brew --prefix cocoapods)/libexec" "$(brew --prefix ruby)/bin/ruby" \
#     tool/ios/add_broadcast_extension.rb
#
# See docs/mobile.md#sharing-the-screen.
require 'xcodeproj'

IOS = File.expand_path('../../ios', __dir__)
PROJECT = File.join(IOS, 'Runner.xcodeproj')

NAME = 'RaindropBroadcast'
DEPLOYMENT_TARGET = '15.0'

project = Xcodeproj::Project.open(PROJECT)
runner = project.targets.find { |target| target.name == 'Runner' }
abort 'Runner target not found' unless runner

if project.targets.any? { |target| target.name == NAME }
  puts "#{NAME} is already in the project; nothing to do."
  exit
end

# Whatever Runner is signed with and called, the extension follows: its bundle
# id has to sit under the app's, and both have to be the same team's.
runner_settings = runner.build_configurations.first.build_settings
bundle_id = runner_settings['PRODUCT_BUNDLE_IDENTIFIER']
team = runner.build_configurations.map { |c| c.build_settings['DEVELOPMENT_TEAM'] }.compact.first

# ── The extension ────────────────────────────────────────────────────────────

group = project.main_group.new_group(NAME, NAME)
source = group.new_file('SampleHandler.swift')
group.new_file('Info.plist')
group.new_file("#{NAME}.entitlements")
xcconfig = group.new_file('Broadcast.xcconfig')

extension = project.new_target(:app_extension, NAME, :ios, DEPLOYMENT_TARGET)
extension.add_file_references([source])

extension.build_configurations.each do |config|
  config.base_configuration_reference = xcconfig
  settings = config.build_settings
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{bundle_id}.#{NAME}"
  settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  settings['INFOPLIST_FILE'] = "#{NAME}/Info.plist"
  settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  settings['CODE_SIGN_ENTITLEMENTS'] = "#{NAME}/#{NAME}.entitlements"
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['DEVELOPMENT_TEAM'] = team if team
  settings['SWIFT_VERSION'] = '5.0'
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  # iPhone and iPad: the same extension is what an iPad shares with.
  settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  settings['SKIP_INSTALL'] = 'YES'
  settings['ENABLE_BITCODE'] = 'NO'
  settings['LD_RUNPATH_SEARCH_PATHS'] = [
    '$(inherited)',
    '@executable_path/Frameworks',
    '@executable_path/../../Frameworks',
  ]
  # An extension may only call what is safe to call from one.
  settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
end

# ── Runner ───────────────────────────────────────────────────────────────────

runner.add_dependency(extension)

# Before "Thin Binary": Flutter's script phases read the built app, and an
# embed phase after them has Xcode report a cycle in Runner's build.
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
embed_file = embed.add_file_reference(extension.product_reference)
embed_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

thin = runner.build_phases.find { |phase| phase.respond_to?(:name) && phase.name == 'Thin Binary' }
if thin
  runner.build_phases.delete(embed)
  runner.build_phases.insert(runner.build_phases.index(thin), embed)
end

# The App Group the two share.
runner_group = project.main_group.children.find { |child| child.display_name == 'Runner' }
if runner_group && runner_group.files.none? { |file| file.display_name == 'Runner.entitlements' }
  runner_group.new_file('Runner.entitlements')
end
runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] ||= 'Runner/Runner.entitlements'
end

project.save
puts "Added #{NAME} (#{bundle_id}.#{NAME}) and embedded it in Runner."
