platform :ios, '10.0'
# Comment the next line if you're not using Swift and don't want to use dynamic frameworks
use_frameworks!

def shared_pods
  # Firebase
  pod 'Firebase/Core', '4.3.0'
  pod 'Firebase/Auth'         # Version determined by /Core
  pod 'Firebase/Database'     # "
  pod 'Firebase/Storage'      # "
  pod 'Firebase/RemoteConfig' # "
  pod 'Firebase/Messaging'      # "
  pod 'FirebaseUI/Storage', '2.0.0'
  pod 'FirebaseInstanceID', '2.0.0'

  # Facebook
  pod 'Bolts', '1.8.4'
  pod 'FacebookCore'
  pod 'FacebookLogin'
  pod 'FacebookShare'
  pod 'FBSDKCoreKit', '4.15.0'
  pod 'FBSDKLoginKit', '4.15.0'
  pod 'FBSDKShareKit', '4.15.0'

  # Appozic
  pod 'Applozic', '4.3.0'

  # RX
  pod 'RxSwift', '3.2.0'
  pod 'RxCocoa', '3.2.0'

  # UI
  pod 'Koloda', :git=> 'https://github.com/woojoapp/Koloda.git'
  #pod 'Koloda', '4.3.1'
  pod 'NMRangeSlider', '1.2.1'
  pod 'RSKImageCropper', '1.6.1'
  pod 'PKHUD', '5.0.0'
  pod 'DZNEmptyDataSet', '1.8.1' 
  pod 'HMSegmentedControl', '1.5.3'
  pod 'DOFavoriteButton', :git=>'https://github.com/woojoapp/DOFavoriteButton', :tag => 'woojo2.0'
  pod 'RPCircularProgress', '0.3.0'
  pod 'ImageSlideshow', '1.0.0'
  pod 'Whisper', :git=> 'https://github.com/woojoapp/Whisper.git', :tag => 'woojo2.0'
  pod 'TTTAttributedLabel', '2.0.0'

  # Misc
  pod 'SDWebImage', '3.8.2'
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