Pod::Spec.new do |s|
  s.name         = "SlidePay_iOS"
  s.version      = "0.0.1"
  s.summary      = "Core SDK for SlidePay"
  s.homepage     = "https://github.com/SlidePay/SlidePay_iOS"
  s.license      = 'LICENSE'
  s.authors      = { "SlidePay" => "api@slidepay.com", "Alex Garcia" => "alex@slidepay.com" }
  s.platform     = :ios, '6.0'
  s.source       = {:git => "https://github.com/SlidePay/SlidePay_iOS.git"}#, :tag => s.version}
  s.requires_arc = true

  s.subspec 'Payments' do |sc|
    sc.dependency 'RestKit', '~>0.20.0'
    sc.ios.frameworks = 'CFNetwork', 'Security', 'MobileCoreServices', 'SystemConfiguration'
    sc.source_files = 'SlidePayCore/','*.h','*.m'
  end

  s.subspec 'Rambler' do |sr|
	  sr.source_files = 'SlidePayHardware/Rambler/','*.h','*.m'
	  sr.libraries = 'SlidePayHardware/Rambler/libReaderAPI-2.0.0-beta1','libReaderAPI-2.0.0-beta1.a','SlidePayHardware/Rambler/libReaderAPI-2.0.0-beta1-simulator','libReaderAPI-2.0.0-beta1-simulator.a'
	  sr.vendored_libraries = 'SlidePayHardware/Rambler/libReaderAPI-2.0.0-beta1.a','SlidePayHardware/Rambler/libReaderAPI-2.0.0-beta1-simulator.a'
	  sr.ios.frameworks = 'AudioToolBox','CoreAudio','MediaPlayer'
  end

  s.subspec 'Magtek' do |sm|
	  sm.source_files = 'SlidePayHardware/Magtek/','*.h','*.m'
  end

end
