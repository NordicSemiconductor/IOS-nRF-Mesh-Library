#
# Be sure to run `pod lib lint nRFMeshProvision.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.coļcoapods.org/syntax/podspec.html
#


Pod::Spec.new do |s|
  s.name             = 'nRFMeshProvision'
  s.version          = '4.0.1'
  s.summary          = 'A Bluetooth Mesh library'
  s.description      = <<-DESC
  nRF Mesh is a Bluetooth mesh compliant library supporting features such as provisioning, configuration and control of Bluetooth mesh nodes.
                       DESC
  s.homepage         = 'https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library'
  s.license          = { :type => 'BSD-3-Clause', :file => 'LICENSE' }
  s.author           = { 'Aleksander Nowakowski' => 'aleksander.nowakowski@nordicsemi.no' }
  s.source           = { :git => 'https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/nordictweets'
  s.ios.deployment_target  = '13.0'
  s.osx.deployment_target  = '10.15'  
  s.static_framework = true
  s.swift_versions   = ['5.5', '5.6', '5.7', '5.8', '5.9']
  s.source_files = 'nRFMeshProvision/**/*'
  s.resource = 'nRFMeshProvision/Resources/PrivacyInfo.xcprivacy'
  s.dependency 'CryptoSwift', '= 1.8.0'
  s.frameworks = 'CoreBluetooth'
end
