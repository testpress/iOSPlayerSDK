[![Swift](https://img.shields.io/badge/Swift-5.5_5.6_5.7_5.8-orange)](https://img.shields.io/badge/Swift-5.5_5.6_5.7_5.8-Orange)
[![Platforms](https://img.shields.io/badge/Platforms-iOS-green)](https://img.shields.io/badge/Platforms-iOS-Green)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange)

# Getting Started

  TPStreamsSDK is a versatile iOS native SDK with support for both DRM (FairPlay) and non-DRM content.

- [Requirements](#requirements)
- [Integration using Swift Package Manager (SPM)](#integration-using-swift-package-manager-(spm))
- [Intializing TPStreamsSDK](#initializing-tpstreamssdk)
- [Playing a Video with TPStreamsSDK](#playing-a-video-with-tpstreamsSDK)
    - [SwiftUI Integration](#SwiftUI-Integration)
    - [UIKit Integration](#UIKit-Integration)
- [Sample iOS app](https://github.com/testpress/sample-iOS-app)

  
### Requirements

Before integrating TPStreamsSDK into your iOS application, ensure that your project meets the following requirement:

- Minimum Deployment Version: iOS 14 or later
- Swift: Version 5.5 or later



### Integration using Swift Package Manager (SPM)

To add TPStreamsSDK to your Xcode project using Swift Package Manager, follow these steps:

- Select File > Add Packages in Xcode.
- In the search bar, enter the following URL: `https://github.com/testpress/iOSPlayerSDK`.
- Select 'iOSPlayerSDK' from the search results. Click Add package button.


Once the package is added, you can start using TPStreamsSDK in your iOS application.



### Initializing TPStreamsSDK

In the `application(_:didFinishLaunchingWithOptions:)` method in your AppDelegate, call `TPStreamsSDK.initialize(withOrgCode:)` to initialize the SDK with your organization code.

 
``` swift

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,didFinishLaunchingWithOptions launchOptions [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        TPStreamsSDK.initialize(withOrgCode: "YOUR_ORGANIZATION_CODE")
        return true
    }
}

```

> Please note that the above code assumes you are using SwiftUI for your application. If you are using a different app architecture, you may need to adapt the integration steps accordingly.



### Playing a Video with TPStreamsSDK

#### SwiftUI Integration
1. Instantiate a TPAVPlayer by providing the appropriate assetID and accessToken.
2. Embed the TPStreamPlayerView in your SwiftUI view.

``` swift

struct ContentView: View {
	let player = TPAVPlayer(assetID: "YOUR_ASSET_ID", accessToken: "YOUR_ACCESS_TOKEN")

	var body: some View {
		VStack {
			TPStreamPlayerView(player: player)
				.frame(height: 240)
			Spacer()
		}
	}
}

```

  

#### UIKit Integration

1. Instantiate a TPAVPlayer with the relevant assetID and accessToken.
2. Create a TPStreamPlayerViewController and assign the previously created TPAVPlayer to the player attribute.
3. Add the TPStreamPlayerViewController.view to the view hierarchy. This will display the video player within the specified playerContainer view.

``` swift
class ViewController: UIViewController {
    @IBOutlet weak var playerContainer: UIView!

    var playerViewController: TPStreamPlayerViewController?
    var player: TPAVPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupPlayerView()
        player?.play()
    }

    func setupPlayerView(){
        player = TPAVPlayer(assetID: "YOUR_ASSET_ID", accessToken: "YOUR_ACCESS_TOKEN")
        playerViewController = TPStreamPlayerViewController()
        playerViewController?.player = player

        addChild(playerViewController!)
        playerContainer.addSubview(playerViewController!.view)
        playerViewController!.view.frame = playerContainer.bounds
    }
}
```
  
 
> TPAVPlayer is a wrapper class of AVPlayer that provides built-in support for playing our videos without requiring
additional effort. It also supports FairPlay streaming for DRM-protected content.

> Since TPAVPlayer is a wrapper class of AVPlayer, you can also use the TPAVPlayer with native iOS player to play Streams
Videos.  



For a practical implementation and usage of TPStreamsSDK, refer to our [Sample iOS App](https://github.com/testpress/sample-iOS-app).

