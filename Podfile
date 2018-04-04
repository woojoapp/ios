platform :ios, '10.0'
# Comment the next line if you're not using Swift and don't want to use dynamic frameworks
use_frameworks!

def shared_pods
  # Firebase
  pod 'Firebase/Core', '4.9.0'
  pod 'Firebase/Auth'         # Version determined by /Core
  pod 'Firebase/Database'     # "
  pod 'Firebase/Storage'      # "
  pod 'Firebase/RemoteConfig' # "
  pod 'Firebase/Messaging'      # "
  pod 'FirebaseUI/Storage', '4.5.1'
  # pod 'FirebaseInstanceID', '2.0.0'
  pod 'Fabric', '~> 1.7.5'
  pod 'Crashlytics', '~> 3.10.1'

  # Branch
  pod 'Branch', '0.19.5'
  pod 'Amplitude-iOS', '4.1.0'

  # Facebook
  # pod 'Bolts', '1.8.4'
  pod 'FacebookCore', '0.3.0'
  pod 'FacebookLogin', '0.3.0'
  pod 'FacebookShare', '0.3.0'
  # pod 'FBSDKCoreKit', '4.21.0'
  # pod 'FBSDKLoginKit', '4.21.0'
  # pod 'FBSDKShareKit', '4.21.0'

  # Appozic
  pod 'Applozic', '5.1.0'
  # pod 'ApplozicSwift', '0.6.0'

  # RX
  pod 'RxSwift', '4.1.2'
  pod 'RxCocoa', '4.1.2'

  # UI
  pod 'Koloda', :git=> 'https://github.com/woojoapp/Koloda.git'
  pod 'NMRangeSlider', '1.2.1'
  pod 'RSKImageCropper', '1.6.1'
  pod 'PKHUD', '5.0.0'
  pod 'DZNEmptyDataSet', '1.8.1' 
  pod 'HMSegmentedControl', '1.5.4'
  # pod 'DOFavoriteButton', :git=>'https://github.com/woojoapp/DOFavoriteButton', :tag => 'woojo2.2.3'
  pod 'RPCircularProgress', '0.3.0'
  pod 'ImageSlideshow', '1.5.0'
  # pod 'Whisper', :git=> 'https://github.com/woojoapp/Whisper.git', :tag => 'woojo2.0'
  pod 'Whisper', '6.0.2'
  pod 'TTTAttributedLabel', '2.0.0'
  pod 'BWWalkthrough', '2.1.2'

  # Misc
  pod 'SDWebImage', '4.2.2'
end

target 'Woojo Development' do
  # Pods for Woojo Development
  shared_pods
end

target 'Woojo Staging' do
  # Pods for Woojo Staging
  shared_pods
end

target 'Woojo' do
  # Pods for Woojo (Production)
  shared_pods
end
