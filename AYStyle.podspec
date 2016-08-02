#
# Be sure to run `pod lib lint AYStyle.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AYStyle'
  s.version          = '1.0.0'
  s.summary          = 'Theme/Font Manage Center.'

  s.homepage         = 'https://github.com/alan-yeh/AYStyle'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alan Yeh' => 'alan@yerl.cn' }
  s.source           = { :git => 'https://github.com/alan-yeh/AYStyle.git', :tag => s.version.to_s }

  s.ios.deployment_target = '6.0'
  s.source_files = 'AYStyle/Classes/**/*'
  s.public_header_files = 'AYStyle/Classes/**/*.h'
  s.frameworks = 'UIKit'
  s.dependency 'AYAspect'
end
