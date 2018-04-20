#
# Be sure to run `pod lib lint nRFMeshProvision.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'nRFMeshProvision'
  s.version          = '0.1'
  s.summary          = 'A Bluetooth Mesh compliant provisioner and configurator'
  s.description      = <<-DESC
An early alpha version of the Bluetooth Mesh specification, this library will allow you to provision and configure bluetooth Mesh compliant nodes.
This is a preview version that has missing features and capabilities that are going to be added in the near future.
                       DESC
  s.homepage         = 'https://github.com/mostafaberg/nRFMeshProvision'
  s.license          = { :type => 'BSD-3-Clause', :file => 'LICENSE' }
  s.author           = { 'mostafaberg' => 'mostafa.berg@nordicsemi.no' }
  s.source           = { :git => 'https://github.com/NordicPlayground/IOS-nRF-Mesh-Library.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/nordictweets'
  s.platform         = :ios
  s.static_framework = true
  s.swift_version    = '4'
  s.ios.deployment_target = '10.0'
  s.source_files = 'nRFMeshProvision/Classes/**/*'
  s.dependency 'OpenSSL'
  s.frameworks = 'CoreBluetooth'
end
