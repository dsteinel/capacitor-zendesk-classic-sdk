require 'json'

  Pod::Spec.new do |s|
    # NPM package specification
    package = JSON.parse(File.read(File.join(File.dirname(__FILE__), 'package.json')))

    s.name = 'CapacitorZendeskClassicSdk'
    s.version = package['version']
    s.summary = package['description']
    s.license = package['license']
    s.homepage = 'https://github.com/dsteinel/capacitor-zendesk-classic-sdk'
    s.author = package['author']
    s.ios.deployment_target  = '17.0'
    s.dependency 'Capacitor'
    s.dependency 'ZendeskSupportSDK'
    s.dependency 'ZendeskChatSDK'
    s.dependency 'ZendeskMessagingSDK'
    s.static_framework = true
    s.source = { :git => 'https://github.com/dsteinel/capacitor-zendesk-classic-sdk.git', :tag => s.version.to_s }
    s.source_files = 'ios/CapacitorZendeskSupportSdk/Source/**/*.{swift,h,m}'
    s.resource_bundles = {
      'CapacitorZendeskClassicSdk' => ['ios/CapacitorZendeskSupportSdk/Source/**/Resources/**/*.strings']
    }
    s.swift_version = '5.0'
  end
