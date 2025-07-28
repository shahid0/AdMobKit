# AdMobKit

AdMobKit is a SwiftUI library for integrating Google AdMob ads (Banner, Interstitial, Rewarded, App Open, and Native) into your iOS apps with minimal setup.

> ⚠️ **Notice:**  
> **AdMobKit v2.0.0 is now released!**  
> This documentation is for **v1.0.0** and **has not yet been updated** for the latest changes.  
> Please refer to the [v1.0.0 tag](https://github.com/shahid0/AdMobKit/tree/1.0.0) for the version this README applies to.  
> Full updated documentation for v2.0.0 is coming soon.
> Example For v2.0.0 is Present inside Combine Example Folder (with onChange Example)


## Table of Contents
- [Features](#features)
- [Background](#background)
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

## Background

As a developer who started directly with **SwiftUI**, integrating Google AdMob into my apps was far from straightforward. I had **no experience with UIKit**, and setting up ad formats like interstitials, rewarded ads, or especially native ads was **frustrating**. Most of the available resources and SDK examples were either UIKit-based or overly complicated, which made it hard to implement cleanly in a SwiftUI-first codebase.

I initially built my own ad integration system for personal use — copy-pasting code between projects, trying to make sense of `UIViewControllerRepresentable`, and managing boilerplate setup across apps. Even using Google's official documentation felt out of reach for someone who just transitioned from **React/Next.js and C++** to Swift and SwiftUI.

Eventually, I decided to **wrap everything into a reusable Swift Package**, so I could just drop in a banner, interstitial, or rewarded ad the same way I’d use any other SwiftUI view. No hacks. No UIViewControllers. Just `.task { await viewModel.loadAd(...) }` and move on.

That’s how **AdMobKit** was born — a lightweight SwiftUI-first library designed to make **ad integration feel native to SwiftUI**.

It’s built for developers like me, and I use it across all my own apps. I decided to open-source it because I believe in **sharing practical tools**, and I hope others will contribute to help **make this more robust and eventually earn a place in official AdMob integration guides**.

There was an older SwiftUI-based AdMob wrapper I saw when I first started, which inspired me to publish my own — this time updated for the **latest AdMob SDK**, more flexible, and more idiomatic for SwiftUI developers.

I welcome contributions, feedback, and ideas to help maintain and grow this project together.


## Installation

### Swift Package Manager
Add this package to your `Package.swift`:

```
.package(url: "https://github.com/shahid0/AdMobKit.git", from: "1.0.0")
```

Or use Xcode's "Add Package" feature.

**Note:**
- The package includes `NativeAdView.xib` and `Media.xcassets` as resources. Ensure your app target is configured to bundle these resources.

## Usage

### Banner Ad (with adLoadFailed binding and dynamic height)
```swift
@State private var bannerAdLoadFailed = false

BannerAdView(AdUnitID: "your-banner-unit-id", adLoadFailed: $bannerAdLoadFailed)
    .frame(maxHeight: bannerAdLoadFailed ? 0 : .infinity) // Hide banner if load fails
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
