#!/usr/bin/env ruby
# Adds the RaindropLiveActivity target — the widget extension that draws the
# call's Live Activity, in the Dynamic Island and on the Lock Screen — to
# ios/Runner.xcodeproj, and wires Runner up to embed it and to start, update
# and end the activity itself (Runner/CallActivity.swift).
#
# The project file it edits is committed, so this does not run as part of any
# build. It is here because that file is not something to edit by hand, and
# because it is the record of exactly what the extension needed: run it again
# after anything regenerates the Xcode project (it changes nothing when the
# target is already there). The sources it points at are in
# ios/RaindropLiveActivity/ and ios/Runner/CallActivity.swift.
#
# It needs the `xcodeproj` gem, which CocoaPods already brings:
#
#   GEM_HOME="$(brew --prefix cocoapods)/libexec" "$(brew --prefix ruby)/bin/ruby" \
#     tool/ios/add_live_activity_extension.rb
#
# See docs/background-and-live-calls.md.
require 'xcodeproj'

IOS = File.expand_path('../../ios', __dir__)
PROJECT = File.join(IOS, 'Runner.xcodeproj')

NAME = 'RaindropLiveActivity'
# Live Activities exist from iOS 16.1, and ActivityContent — what the app
# updates them with — from 16.2. The app itself still runs on 15; it only
# shows no activity there.
DEPLOYMENT_TARGET = '16.2'

# Compiled into both targets: the app starts the activity with these
# attributes and runs the buttons' intents; the extension draws them.
SHARED = %w[CallActivityAttributes.swift CallActivityIntents.swift].freeze
EXTENSION_ONLY = %w[CallActivityViews.swift RaindropLiveActivity.swift].freeze

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
shared = SHARED.map { |file| group.new_file(file) }
own = EXTENSION_ONLY.map { |file| group.new_file(file) }
group.new_file('Info.plist')
xcconfig = group.new_file('LiveActivity.xcconfig')

extension = project.new_target(:app_extension, NAME, :ios, DEPLOYMENT_TARGET)
extension.add_file_references(shared + own)

extension.build_configurations.each do |config|
  config.base_configuration_reference = xcconfig
  settings = config.build_settings
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{bundle_id}.#{NAME}"
  settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  settings['INFOPLIST_FILE'] = "#{NAME}/Info.plist"
  settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['DEVELOPMENT_TEAM'] = team if team
  settings['SWIFT_VERSION'] = '5.0'
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  # iPhone and iPad: an iPad shows the Lock Screen presentation.
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
runner.add_file_references(shared)

runner_group = project.main_group.children.find { |child| child.display_name == 'Runner' }
abort 'Runner group not found' unless runner_group
controller = runner_group.files.find { |file| file.display_name == 'CallActivity.swift' } ||
             runner_group.new_file('CallActivity.swift')
runner.add_file_references([controller])

# ActivityKit and AppIntents are newer than the app's iOS 15: linked weakly, so
# the app still launches there, and only shows no activity.
runner.build_configurations.each do |config|
  flags = Array(config.build_settings['OTHER_LDFLAGS'] || ['$(inherited)'])
  %w[ActivityKit AppIntents].each do |framework|
    next if flags.each_cons(2).any? { |a, b| a == '-weak_framework' && b == framework }
    flags += ['-weak_framework', framework]
  end
  config.build_settings['OTHER_LDFLAGS'] = flags
end

# Into the same phase as the broadcast extension — which sits before Flutter's
# "Thin Binary", as it has to.
embed = runner.copy_files_build_phases.find { |phase| phase.name == 'Embed Foundation Extensions' }
unless embed
  embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
  embed.symbol_dst_subfolder_spec = :plug_ins
  thin = runner.build_phases.find { |phase| phase.respond_to?(:name) && phase.name == 'Thin Binary' }
  if thin
    runner.build_phases.delete(embed)
    runner.build_phases.insert(runner.build_phases.index(thin), embed)
  end
end
embed_file = embed.add_file_reference(extension.product_reference)
embed_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

project.save
puts "Added #{NAME} (#{bundle_id}.#{NAME}) and embedded it in Runner."
