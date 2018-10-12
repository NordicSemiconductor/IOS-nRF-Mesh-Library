#
# Be sure to run `pod lib lint nRFMeshProvision.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'nRFMeshProvision'
  s.version          = '1.0.3'
  s.summary          = 'A Bluetooth Mesh library'
  s.description      = <<-DESC
  nRF Mesh is a Bluetooth Mesh compliant library that has many features such as provisioning, configuration and control of Bluetooth Mesh compliant nodes.
This Library is under extensive development and will have missing features and capabilities that are going to be added in the near future.
                       DESC
  s.homepage         = 'https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library'
  s.license          = { :type => 'BSD-3-Clause', :file => 'LICENSE' }
  s.author           = { 'mostafaberg' => 'mostafa.berg@nordicsemi.no' }
  s.source           = { :git => 'https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/nordictweets'
  s.platform         = :ios
  s.static_framework = true
  s.swift_version    = '4'
  s.ios.deployment_target = '10.0'
  s.source_files = 'nRFMeshProvision/Classes/**/*'
  s.dependency 'OpenSSL'
  s.frameworks = 'CoreBluetooth'
end
