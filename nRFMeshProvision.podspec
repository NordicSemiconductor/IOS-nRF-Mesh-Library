#
# Be sure to run `pod lib lint nRFMeshProvision.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'nRFMeshProvision'
  s.version          = '2.0.0'
  s.summary          = 'A Bluetooth Mesh library'
  s.description      = <<-DESC
  nRF Mesh is a Bluetooth Mesh compliant library that has many features such as provisioning, configuration and control of Bluetooth Mesh compliant nodes.
                       DESC
  s.homepage         = 'https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library'
  s.license          = { :type => 'BSD-3-Clause', :file => 'LICENSE' }
  s.author           = { 'Aleksander Nowakowski' => 'aleksander.nowakowski@nordicsemi.no' }
  s.source           = { :git => 'https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/nordictweets'
  s.platform         = :ios
  s.static_framework = true
  s.swift_version    = '5.0'
  s.ios.deployment_target = '10.0'
  s.source_files = 'nRFMeshProvision/Classes/**/*'
  s.dependency 'OpenSSL-Universal', '= 1.0.2.19'
  s.frameworks = 'CoreBluetooth'
end
