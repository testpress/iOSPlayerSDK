Pod::Spec.new do |spec|
  spec.name         = "TPStreamsSDK"
  spec.version      = "1.2.18"
  spec.summary      = "Integrate TPStreams video playback seamlessly into your iOS app with our powerful iOS player SDK."
  spec.description  = "TPStreamsSDK is a versatile iOS native SDK with support for both DRM (FairPlay) and non-DRM content."
  spec.homepage     = "https://developer.tpstreams.com/docs/mobile-sdk/ios-native-sdk/getting-started"
  spec.license      = { :type => "Apache License", :file => "LICENSE" }
  spec.author             = { "hari-testpress" => "hari@testpress.in" }
  spec.ios.deployment_target = "12.0"
  spec.swift_versions = '5.0'
  spec.source       = { :git => "https://github.com/testpress/iOSPlayerSDK.git", :tag => spec.version }
  spec.source_files  = "Source/**/*.{swift,plist}"
  spec.exclude_files = "Classes/Exclude"
  spec.dependency 'Sentry', '~> 8.50.0'
  spec.dependency 'Alamofire', '~> 5.9.0'
  spec.dependency 'M3U8Kit', '~> 1.2.0'
  spec.dependency 'ReachabilitySwift', '~> 5.2.2'
  spec.dependency 'RealmSwift', '~> 10.54.2'
  spec.dependency 'Toast-Swift', '~> 5.1.1'

  spec.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS[config=Debug]' => '-DCocoaPods',
    'OTHER_SWIFT_FLAGS[config=Release]' => '-DCocoaPods'
}

  spec.resources = [
    'Source/**/*.{xcassets}',
    'Source/**/*.{xib,storyboard}'
  ]
  spec.resource_bundles = {
    'TPStreamsSDKResources' => [
      'Source/**/*.{json,png}',
      'PrivacyInfo.xcprivacy'
    ]
  }
end
