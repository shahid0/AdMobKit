# AdMobKit

AdMobKit is a SwiftUI library for integrating Google AdMob ads (Banner, Interstitial, Rewarded, App Open, and Native) into your iOS apps with minimal setup.

## Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  - [Banner Ad](#banner-ad-with-adloadfailed-binding-and-dynamic-height)
  - [Interstitial Ad](#interstitial-ad-loading-and-showing-with-callbacks)
  - [Rewarded Ad](#rewarded-ad-loading-showing-and-listening-to-coin-changes)
  - [Rewarded Interstitial Ad](#rewarded-interstitial-ad-loading-showing-and-listening-to-coin-changes)
  - [App Open Ad](#app-open-ad-loading-and-showing-with-callbacks)
  - [Preventing App Open Ads on InAppPaywall Screens](#preventing-app-open-ads-on-inapppaywall-screens)
  - [Native Ad](#native-ad-loading-and-showing)
- [Asset Integration](#asset-integration)
- [API Reference](#api-reference)
- [License](#license)
- [Credits](#credits)

## Features
- Banner Ads
- Interstitial Ads
- Rewarded Ads
- Rewarded Interstitial Ads
- App Open Ads
- Native Ads (with customizable views)
- SwiftUI and UIKit compatible
- Easy-to-use view models and SwiftUI wrappers
- Includes XIB and media assets for native ad rendering

## Installation

### Swift Package Manager
Add this package to your `Package.swift`:

```
.package(url: "<your-repo-url>", from: "1.0.0")
```

Or use Xcode's "Add Package" feature.

**Note:**
- The package includes `NativeAdView.xib` and `Media.xcassets` as resources. Ensure your app target is configured to bundle these resources.

## Usage

### Banner Ad (with adLoadFailed binding and dynamic height)
```swift
@State private var bannerAdLoadFailed = false
BannerAdView(AdUnitID: "your-banner-unit-id", adLoadFailed: $bannerAdLoadFailed)
    .frame(height: bannerAdLoadFailed ? 0 : .infinity) // Hide banner if load fails
// You can use your own logic for hiding or resizing the banner.
```

### Interstitial Ad (loading and showing, with callbacks)
```swift
@StateObject var interstitialVM = InterstitialViewModel()

// Listen for ad events
interstitialVM.onAdLoadComplete = { print("Interstitial loaded!") }
interstitialVM.onAdDismiss = { print("Interstitial will dismiss!") } // adWillDismiss
interstitialVM.onAdDismissed = { print("Interstitial fully dismissed!") } // adDidDismiss

// Load and show
.task { await interstitialVM.loadAd(adUnitID: "your-interstitial-unit-id") }
Button("Show Interstitial") { interstitialVM.showAd() }
```

### Rewarded Ad (loading, showing, and listening to coin changes)
```swift
@StateObject var rewardedVM = RewardedViewModel()

// Listen for ad events
rewardedVM.onAdLoadComplete = { print("Rewarded loaded!") }
rewardedVM.onAdDismiss = { print("Rewarded will dismiss!") } // adWillDismiss
rewardedVM.onAdDismissed = { print("Rewarded fully dismissed!") } // adDidDismiss

// Listen for coin changes
.onChange(of: rewardedVM.coins) { newCoins in
    print("User coins: \(newCoins)")
}

// Load and show
.task { await rewardedVM.loadAd(adUnitID: "your-rewarded-unit-id") }
Button("Show Rewarded") { rewardedVM.showAd() }
```

### Rewarded Interstitial Ad (loading, showing, and listening to coin changes)
```swift
@StateObject var rewardedInterstitialVM = RewardedInterstitialViewModel()

// Listen for ad events
rewardedInterstitialVM.onAdLoadComplete = { print("Rewarded Interstitial loaded!") }
rewardedInterstitialVM.onAdDismiss = { print("Rewarded Interstitial will dismiss!") } // adWillDismiss
rewardedInterstitialVM.onAdDismissed = { print("Rewarded Interstitial fully dismissed!") } // adDidDismiss

// Listen for coin changes
.onChange(of: rewardedInterstitialVM.coins) { newCoins in
    print("User coins: \(newCoins)")
}

// Load and show
.task { await rewardedInterstitialVM.loadAd(adUnitID: "your-rewarded-interstitial-unit-id") }
Button("Show Rewarded Interstitial") { rewardedInterstitialVM.showAd() }
```

### App Open Ad (loading and showing, with callbacks)
```swift
@StateObject var appOpenVM = AppOpenAdManager()

// Listen for ad events (if needed)
// appOpenVM exposes isLoadingAd, isShowingAd, etc.

// Load and show
.task { await appOpenVM.loadAd(adUnitID: "your-app-open-unit-id") }
Button("Show App Open") { appOpenVM.showAdIfAvailable() }
```

### Preventing App Open Ads on InApp/Paywall Screens
If you want to prevent App Open ads from showing when the user is on an InApp/Paywall screen (e.g., using SwiftUI scenePhase or view lifecycle):

```swift
import SwiftUI

struct PaywallView: View {
    var body: some View {
        Text("Paywall")
            .onAppear {
                AppOpenAdManager.isInProScreen = true // Prevent App Open ads
            }
            .onDisappear {
                AppOpenAdManager.isInProScreen = false // Allow App Open ads again
            }
    }
}
```

Set `AppOpenAdManager.isInProScreen = true` when your paywall or in-app purchase screen appears, and set it back to `false` when it disappears. This will prevent App Open ads from being shown while the user is on these screens.

### Native Ad (loading and showing)
```swift
@StateObject var nativeVM = NativeAdViewModel(adUnitID: "your-native-unit-id")
// Load ad
.task { nativeVM.refreshAd() }
// Show ad
GoogleNativeAdView(nativeViewModel: nativeVM, style: .card)
    .frame(height: 380)
```

## Asset Integration
- The package includes `NativeAdView.xib` and `Media.xcassets` (with star rating images for native ads).
- These are automatically bundled if you use Swift Package Manager and Xcode 12+.

## API Reference
- All view models expose public properties for ad state, loading, and callbacks:
    - `onAdLoadComplete` for ad loaded
    - `onAdDismiss` for ad will dismiss (adWillDismiss)
    - `onAdDismissed` for ad fully dismissed (adDidDismiss)
    - `coins` for rewarded ads (observe with `.onChange`)
    - `isLoadingAd`, `isShowingAd` for AppOpenAdManager
- All ad control methods (`loadAd`, `showAd`, `refreshAd`, `showAd`, etc.) are public.
- See source code for detailed documentation comments.

## License
MIT

## Credits
Created and maintained by **Shahid Hussain**. 