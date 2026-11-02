require 'json'

plugin_version = File.read(File.join(__dir__, '..', 'pubspec.yaml'))[/^version: (\S+)/, 1]
native_sdk = JSON.parse(File.read(File.join(__dir__, '..', 'native-sdk.json')))
native_major_minor = native_sdk['version'].split('.').first(2).join('.')

Pod::Spec.new do |s|
  s.name = 'appy_sdk'
  s.version = plugin_version
  s.summary = 'Flutter plugin for the Appy iOS SDK: deep links, deferred deep links, install attribution and events.'
  s.homepage = 'https://appy.to/docs/sdk/flutter'
  s.license = { :type => 'MIT', :file => '../LICENSE' }
  s.author = { 'Appy' => 'support@appy.to' }
  s.source = { :path => '.' }
  s.source_files = 'appy_sdk/Sources/appy_sdk/**/*.swift'
  s.dependency 'Flutter'
  s.dependency 'AppySDK', "~> #{native_major_minor}"
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'
end
