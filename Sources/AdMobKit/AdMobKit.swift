//
//  AdMobkit.swift
//  AdMobKit
//
//  Created by Shahid hussain on 08/07/2025.
//

import Foundation
import GoogleMobileAds
import SwiftUI
import UIKit

/**
 AdMobKit: A SwiftUI library for integrating Google AdMob ads (Banner, Interstitial, Rewarded, App Open, and Native) into your iOS apps with minimal setup.

 - Supports: Banner, Interstitial, Rewarded, Rewarded Interstitial, App Open, and Native ads.
 - SwiftUI and UIKit compatible.
 - Includes customizable native ad views and easy-to-use view models.
*/
/**
 BannerAdView displays a Google AdMob banner ad in SwiftUI.

 Usage:
 ```swift
 BannerAdView(AdUnitID: "your-banner-unit-id")
     .frame(height: 60)
 ```
 - Parameter AdUnitID: Your AdMob banner ad unit ID.
 - Parameter adLoadFailed: Optional binding to observe ad load failure.
*/
public struct BannerAdView: View {
    /// The AdMob banner ad unit ID.
    public let AdUnitID: String
    /// Binding to observe ad load failure.
    @Binding public var adLoadFailed: Bool
    /**
     Initialize a BannerAdView.
     - Parameters:
        - AdUnitID: Your AdMob banner ad unit ID.
        - adLoadFailed: Optional binding for ad load failure.
    */
    public init(
        AdUnitID: String,
        adLoadFailed: Binding<Bool> = .constant(false)
    ) {
        self.AdUnitID = AdUnitID
        self._adLoadFailed = adLoadFailed
    }
    /// SwiftUI body for the banner ad.
    public var body: some View {
        GeometryReader { proxy in
            let adSize = currentOrientationAnchoredAdaptiveBanner(
                width: proxy.size.width
            )
            VStack {
                BannerViewContainer(
                    for: AdUnitID,
                    adSize,
                    adLoadFailed: $adLoadFailed
                )
            }
        }
    }
}

private struct BannerViewContainer: UIViewRepresentable {
    typealias UIViewType = BannerView

    let AdUnitId: String
    let adSize: AdSize
    @Binding var adLoadFailed: Bool

    init(for AdUnitId: String, _ adSize: AdSize, adLoadFailed: Binding<Bool>) {
        self.adSize = adSize
        self.AdUnitId = AdUnitId
        self._adLoadFailed = adLoadFailed
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        // [START load_ad]
        banner.adUnitID = AdUnitId
        banner.load(Request())
        // [END load_ad]
        // [START set_delegate]
        banner.delegate = context.coordinator
        // [END set_delegate]
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
    }

    func makeCoordinator() -> BannerCoordinator {
        return BannerCoordinator(self)
    }
    // [END create_banner_view]

    class BannerCoordinator: NSObject, BannerViewDelegate {

        var parent: BannerViewContainer

        init(_ parent: BannerViewContainer) {
            self.parent = parent
        }

        // MARK: - BannerViewDelegate methods

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("DID RECEIVE AD.")
            DispatchQueue.main.async {
                self.parent.adLoadFailed = false
                bannerView.isHidden = false
            }
        }

        func bannerView(
            _ bannerView: BannerView,
            didFailToReceiveAdWithError error: Error
        ) {
            print("FAILED TO RECEIVE AD: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.parent.adLoadFailed = true
            }
        }

        func bannerViewDidRecordImpression(_ bannerView: BannerView) {
            print(#function)
        }

        func bannerViewDidRecordClick(_ bannerView: BannerView) {
            print(#function)
        }
    }
}

public class InterstitialViewModel: NSObject, ObservableObject,
    FullScreenContentDelegate
{
    private var interstitialAd: InterstitialAd?
    @Published public var onAdLoadComplete: (() -> Void)?
    @Published public var onAdDismiss: (() -> Void)?
    @Published public var onAdDismissed: (() -> Void)?

    public var isLoading = false

    public override init() { super.init() }

    public func loadAd(adUnitID: String) async {
        guard !isLoading, interstitialAd == nil else { return }
        isLoading = true
        do {
            interstitialAd = try await InterstitialAd.load(
                with: adUnitID,
                request: Request()
            )

            interstitialAd?.fullScreenContentDelegate = self
        } catch {
            print(
                "Failed to load interstitial ad with error: \(error.localizedDescription)"
            )
        }
        isLoading = false
        onAdLoadComplete?()
    }
    // [END load_ad]

    // [START show_ad]
    public func showAd() {
        guard !isLoading else {
            return print("is Loading Ad")
        }
        guard let interstitialAd = interstitialAd else {
            onAdDismiss?()
            return print("Ad wasn't ready.")
        }

        interstitialAd.present(from: nil)
    }
    // [END show_ad]

    // MARK: - FullScreenContentDelegate methods

    // [START ad_events]
    public func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    public func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    public func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        print("\(#function) called")
        onAdDismiss?()
    }

    public func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    public func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
        onAdDismiss?()
    }

    public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
        // Clear the interstitial ad.
        interstitialAd = nil
        onAdDismissed?()
    }
    // [END ad_events]
}

public class RewardedViewModel: NSObject, ObservableObject,
    FullScreenContentDelegate
{
    @Published public var coins = 0
    private var rewardedAd: RewardedAd?
    
    @Published public var onAdLoadComplete: (() -> Void)?
    @Published public var onAdDismiss: (() -> Void)?
    @Published public var onAdDismissed: (() -> Void)?

    public override init() { super.init() }

    public func loadAd(adUnitID: String) async {
        do {
            rewardedAd = try await RewardedAd.load(
                with: adUnitID,
                request: Request()
            )
            // [START set_the_delegate]
            rewardedAd?.fullScreenContentDelegate = self
            // [END set_the_delegate]
        } catch {
            print(
                "Failed to load rewarded ad with error: \(error.localizedDescription)"
            )
        }
        onAdLoadComplete?()
    }
    // [END load_ad]

    // [START show_ad]
    public func showAd() {
        guard let rewardedAd = rewardedAd else {
            return print("Ad wasn't ready.")
        }

        rewardedAd.present(from: nil) {
            let reward = rewardedAd.adReward
            print("Reward amount: \(reward.amount)")
            self.addCoins(reward.amount.intValue)
        }
    }
    // [END show_ad]

    func addCoins(_ amount: Int) {
        coins += amount
    }

    // MARK: - FullScreenContentDelegate methods

    // [START ad_events]
    public func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    public func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    public func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        onAdDismiss?()
        print("\(#function) called")
    }

    public func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    public func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        onAdDismiss?()
        print("\(#function) called")
    }

    public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        onAdDismissed?()
        print("\(#function) called")
        
        // Clear the rewarded ad.
        rewardedAd = nil
    }
}

public class RewardedInterstitialViewModel: NSObject, ObservableObject,
    FullScreenContentDelegate
{
    @Published public var coins = 0
    private var rewardedInterstitialAd: RewardedInterstitialAd?
    
    @Published public var onAdLoadComplete: (() -> Void)?
    @Published public var onAdDismiss: (() -> Void)?
    @Published public var onAdDismissed: (() -> Void)?
    
    public override init() { super.init() }

    public func loadAd(adUnitID: String) async {
        do {
            rewardedInterstitialAd = try await RewardedInterstitialAd.load(
                with: adUnitID,
                request: Request()
            )
            // [START set_the_delegate]
            rewardedInterstitialAd?.fullScreenContentDelegate = self
            // [END set_the_delegate]
        } catch {
            print(
                "Failed to load rewarded interstitial ad with error: \(error.localizedDescription)"
            )
        }
        onAdLoadComplete?()
    }
    // [END load_ad]

    // [START show_ad]
    public func showAd() {
        guard let rewardedInterstitialAd = rewardedInterstitialAd else {
            return print("Ad wasn't ready.")
        }

        rewardedInterstitialAd.present(from: nil) {
            let reward = rewardedInterstitialAd.adReward
            print("Reward amount: \(reward.amount)")
            self.addCoins(reward.amount.intValue)
        }
    }
    // [END show_ad]

    func addCoins(_ amount: Int) {
        coins += amount
    }

    // MARK: - FullScreenContentDelegate methods

    // [START ad_events]
    public func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }
    public func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    public func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        onAdDismiss?()
        print("\(#function) called")
    }

    public func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    public func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        onAdDismiss?()
        print("\(#function) called")
    }

    public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
        onAdDismissed?()
        // Clear the rewarded interstitial ad.
        rewardedInterstitialAd = nil
    }
    // [END ad_events]
}

public class AppOpenAdManager: NSObject, FullScreenContentDelegate,
    ObservableObject
{
    private var appOpenAd: AppOpenAd?
    public var isLoadingAd = false
    public var isShowingAd = false
    public var loadTime: Date?
    public let fourHoursInSeconds = TimeInterval(3600 * 4)
    public static var isInProScreen = false
    // ...

    public override init() { super.init() }

    public func loadAd(adUnitID: String) async {
        // Do not load ad if there is an unused ad or one is already loading.
        if isLoadingAd || isAdAvailable() || Self.isInProScreen {
            return
        }
        isLoadingAd = true

        do {
            appOpenAd = try await AppOpenAd.load(
                with: adUnitID,
                request: Request()
            )
            appOpenAd?.fullScreenContentDelegate = self
            loadTime = Date()
        } catch {
            print(
                "App open ad failed to load with error: \(error.localizedDescription)"
            )
        }
        isLoadingAd = false
    }

    public func showAdIfAvailable() {
        // If the app open ad is already showing, do not show the ad again.
        guard !isShowingAd, !Self.isInProScreen else { return }

        // If the app open ad is not available yet but is supposed to show, load
        // a new ad.
        //        if !isAdAvailable() {
        //            Task {
        //                await loadAd()
        //            }
        //            return
        //        }

        if let ad = appOpenAd {
            isShowingAd = true
            ad.present(from: nil)
        }
    }

    private func wasLoadTimeLessThanFourHoursAgo() -> Bool {
        guard let loadTime = loadTime else { return false }
        // Check if ad was loaded more than four hours ago.
        return Date().timeIntervalSince(loadTime) < fourHoursInSeconds
    }

    private func isAdAvailable() -> Bool {
        // Check if ad exists and can be shown.
        return appOpenAd != nil && wasLoadTimeLessThanFourHoursAgo()
    }

    public func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("App open ad will be presented.")
    }

    public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        appOpenAd = nil
        isShowingAd = false
        // Reload an ad.
        //        Task {
        //            await loadAd()
        //        }
    }

    public func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        appOpenAd = nil
        isShowingAd = false
        // Reload an ad.
        //        Task {
        //            await loadAd()
        //        }
    }
}

public class NativeAdViewModel: NSObject, ObservableObject,
    NativeAdLoaderDelegate
{
    @Published public var nativeAd: NativeAd?
    @Published public var isLoading: Bool = false
    private var adLoader: AdLoader!
    private var adUnitID: String
    private var lastRequestTime: Date?
    public var requestInterval: Int
    private static var cachedAds: [String: NativeAd] = [:]
    private static var lastRequestTimes: [String: Date] = [:]

    public init(
        adUnitID: String = "ca-app-pub-3940256099942544/3986624511",
        requestInterval: Int = 1 * 60
    ) {
        self.adUnitID = adUnitID
        self.requestInterval = requestInterval
        self.nativeAd = NativeAdViewModel.cachedAds[adUnitID]
        self.lastRequestTime = NativeAdViewModel.lastRequestTimes[adUnitID]
    }

    public func refreshAd() {
        let now = Date()

        if nativeAd != nil, let lastRequest = lastRequestTime,
            now.timeIntervalSince(lastRequest) < Double(requestInterval)
        {
            print(
                "The last request was made less than \(requestInterval / 60) minutes ago. New request is canceled."
            )
            return
        }

        guard !isLoading else {
            print("Previous request is still loading, new request is canceled.")
            return
        }

        isLoading = true
        lastRequestTime = now
        NativeAdViewModel.lastRequestTimes[adUnitID] = now

        let adViewOptions = NativeAdViewAdOptions()
        adViewOptions.preferredAdChoicesPosition = .topRightCorner
        adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: [adViewOptions]
        )
        adLoader.delegate = self
        adLoader.load(Request())
    }

    public func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        self.nativeAd = nativeAd
        nativeAd.delegate = self
        self.isLoading = false
        NativeAdViewModel.cachedAds[adUnitID] = nativeAd
        nativeAd.mediaContent.videoController.delegate = self
    }

    public func adLoader(
        _ adLoader: AdLoader,
        didFailToReceiveAdWithError error: Error
    ) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
        self.isLoading = false
    }
}

extension NativeAdViewModel: VideoControllerDelegate {
    // VideoControllerDelegate methods
    public func videoControllerDidPlayVideo(_ videoController: VideoController)
    {
        // Implement this method to receive a notification when the video controller
        // begins playing the ad.
    }

    public func videoControllerDidPauseVideo(_ videoController: VideoController)
    {
        // Implement this method to receive a notification when the video controller
        // pauses the ad.
    }

    public func videoControllerDidEndVideoPlayback(
        _ videoController: VideoController
    ) {
        // Implement this method to receive a notification when the video controller
        // stops playing the ad.
    }

    public func videoControllerDidMuteVideo(_ videoController: VideoController)
    {
        // Implement this method to receive a notification when the video controller
        // mutes the ad.
    }

    public func videoControllerDidUnmuteVideo(
        _ videoController: VideoController
    ) {
        // Implement this method to receive a notification when the video controller
        // unmutes the ad.
    }
}

// MARK: - NativeAdDelegate implementation
extension NativeAdViewModel: NativeAdDelegate {
    public func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        print("\(#function) called")
    }

    public func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        print("\(#function) called")
    }

    public func nativeAdWillPresentScreen(_ nativeAd: NativeAd) {
        print("\(#function) called")
    }

    public func nativeAdWillDismissScreen(_ nativeAd: NativeAd) {
        print("\(#function) called")
    }

    public func nativeAdDidDismissScreen(_ nativeAd: NativeAd) {
        print("\(#function) called")
    }
}

// [START add_view_model_to_view]

public struct GoogleNativeAdView: UIViewRepresentable {
    public typealias UIViewType = NativeAdView

    @ObservedObject var nativeViewModel: NativeAdViewModel
    var style: NativeAdViewStyle

    public init(
        nativeViewModel: NativeAdViewModel,
        style: NativeAdViewStyle = .basic
    ) {
        self.nativeViewModel = nativeViewModel
        self.style = style
    }

    public func makeUIView(context: Context) -> NativeAdView {
        return style.view
    }

    func removeCurrentSizeConstraints(from mediaView: UIView) {
        mediaView.constraints.forEach { constraint in
            if constraint.firstAttribute == .width
                || constraint.firstAttribute == .height
            {
                mediaView.removeConstraint(constraint)
            }
        }
    }

    public func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
        guard let nativeAd = nativeViewModel.nativeAd else { return }

        if let mediaView = nativeAdView.mediaView {
            mediaView.contentMode = .scaleAspectFill
            mediaView.clipsToBounds = true

            let aspectRatio = nativeAd.mediaContent.aspectRatio

            debugPrint(
                "Google aspectRatio: \(aspectRatio), hasVideoContent: \(nativeAd.mediaContent.hasVideoContent)"
            )

            if style == .largeBanner {
                removeCurrentSizeConstraints(from: mediaView)
                if aspectRatio > 0 {
                    if aspectRatio > 1 {
                        mediaView.widthAnchor.constraint(
                            equalTo: mediaView.heightAnchor,
                            multiplier: aspectRatio
                        ).isActive = true
                    } else {
                        mediaView.widthAnchor.constraint(
                            equalTo: mediaView.heightAnchor,
                            multiplier: 1
                        ).isActive = true
                    }
                } else {
                    mediaView.widthAnchor.constraint(
                        equalTo: mediaView.heightAnchor,
                        multiplier: 16 / 9
                    ).isActive = true
                }
            }
        }

        // headline require
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline

        // body
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil

        // icon
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        nativeAdView.iconView?.isHidden = (nativeAd.icon == nil)

        // ratting
        let starRattingImage = imageOfStars(from: nativeAd.starRating)
        (nativeAdView.starRatingView as? UIImageView)?.image = starRattingImage
        nativeAdView.starRatingView?.isHidden = (starRattingImage == nil)

        // store
        (nativeAdView.storeView as? UILabel)?.text = nativeAd.store
        nativeAdView.storeView?.isHidden = nativeAd.store == nil

        // price
        (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
        nativeAdView.priceView?.isHidden = nativeAd.price == nil

        // advertiser
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        nativeAdView.advertiserView?.isHidden = (nativeAd.advertiser == nil)

        // button
        (nativeAdView.callToActionView as? UIButton)?.setTitle(
            nativeAd.callToAction,
            for: .normal
        )
        nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil
        nativeAdView.callToActionView?.isUserInteractionEnabled = false

        if style == .largeBanner, let body = nativeAd.body, body.count > 0 {
            nativeAdView.callToActionView?.isHidden = true
        }

        // Associate the native ad view with the native ad object. This is required to make the ad clickable.
        // Note: this should always be done after populating the ad views.
        nativeAdView.nativeAd = nativeAd
    }
}

extension GoogleNativeAdView {

    func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
        guard let rating = starRating?.doubleValue else {
            return nil
        }

        let bundle = Bundle.main

        if rating >= 5 {
            return UIImage(named: "stars_5", in: bundle, compatibleWith: nil)
        } else if rating >= 4.5 {
            return UIImage(named: "stars_4_5", in: bundle, compatibleWith: nil)
        } else if rating >= 4 {
            return UIImage(named: "stars_4", in: bundle, compatibleWith: nil)
        } else if rating >= 3.5 {
            return UIImage(named: "stars_3_5", in: bundle, compatibleWith: nil)
        } else {
            return nil
        }
    }
}

public class NativeAdCardView: NativeAdView {

    private let adTag: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString(
            "AD",
            bundle: .main,
            comment: "Ad tag label"
        )
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = .orange
        label.layer.cornerRadius = 2
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: 25)
        ])
        return label
    }()

    private let headlineLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let advertiserLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let iconImageView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 40),
            view.heightAnchor.constraint(equalToConstant: 40),
        ])
        return view
    }()

    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let starRatingImageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 100),
            view.heightAnchor.constraint(equalToConstant: 17),
        ])
        return view
    }()

    private let callToActionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.backgroundColor = UIColor(
            red: 56 / 255,
            green: 113 / 255,
            blue: 224 / 255,
            alpha: 1
        )
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.isUserInteractionEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 39).isActive = true
        return button
    }()

    private let myMediaView: MediaView = {
        let mediaView = MediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        return mediaView
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.headlineView = headlineLabel
        self.iconView = iconImageView
        self.bodyView = bodyLabel
        self.starRatingView = starRatingImageView
        self.callToActionView = callToActionButton
        self.mediaView = myMediaView
        self.advertiserView = advertiserLabel

        // Media view height constraint: 16:9 aspect ratio
        NSLayoutConstraint.activate([
            myMediaView.heightAnchor.constraint(
                equalTo: myMediaView.widthAnchor,
                multiplier: 9.0 / 16.0
            )
        ])

        // AD + star rating + advertiser
        let starRatingRow = UIStackView(arrangedSubviews: [
            adTag, starRatingImageView, advertiserLabel, UIView(),
        ])
        starRatingRow.axis = .horizontal
        starRatingRow.spacing = 4
        starRatingRow.alignment = .center

        let headlineSection = UIStackView(arrangedSubviews: [
            headlineLabel, starRatingRow,
        ])
        headlineSection.axis = .vertical
        headlineSection.spacing = 8

        let iconStack = UIStackView(arrangedSubviews: [iconImageView])
        iconStack.axis = .vertical

        let topRow = UIStackView(arrangedSubviews: [
            iconStack, headlineSection, UIView(),
        ])
        topRow.axis = .horizontal
        topRow.spacing = 8
        topRow.alignment = .center

        let ctaContainer = UIStackView(arrangedSubviews: [callToActionButton])
        ctaContainer.axis = .horizontal
        ctaContainer.alignment = .fill
        ctaContainer.distribution = .fill
        ctaContainer.layoutMargins = UIEdgeInsets(
            top: 0,
            left: 10,
            bottom: 0,
            right: 10
        )
        ctaContainer.isLayoutMarginsRelativeArrangement = true

        let bottomStack = UIStackView(arrangedSubviews: [
            topRow, bodyLabel, ctaContainer,
        ])
        bottomStack.axis = .vertical
        bottomStack.spacing = 8
        bottomStack.layoutMargins = UIEdgeInsets(
            top: 10,
            left: 10,
            bottom: 10,
            right: 10
        )
        bottomStack.isLayoutMarginsRelativeArrangement = true

        let fullStack = UIStackView(arrangedSubviews: [
            myMediaView, bottomStack,
        ])
        fullStack.axis = .vertical
        fullStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(fullStack)

        NSLayoutConstraint.activate([
            fullStack.topAnchor.constraint(equalTo: topAnchor),
            fullStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            fullStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            fullStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
public enum NativeAdViewStyle {
    case basic
    case card
    case banner
    case largeBanner

    var view: NativeAdView {
        switch self {
        case .basic:
            return makeNibView(name: "NativeAdView")
        case .card:
            return NativeAdCardView(frame: .zero)
        case .banner:
            return NativeAdBannerView(frame: .zero)
        case .largeBanner:
            return NativeLargeAdBannerView(frame: .zero)
        }
    }

    func makeNibView(name: String) -> NativeAdView {
        let bundle = Bundle.main
        let nib = UINib(nibName: name, bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first
            as! NativeAdView

    }
}

public class NativeLargeAdBannerView: NativeAdView {

    // MARK: - Required Views
    private let myMediaView: MediaView = {
        let view = MediaView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()

    private let headlineLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let adTag: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString(
            "AD",
            bundle: .main,
            comment: "Ad tag label"
        )
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.backgroundColor = .systemFill
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Optional Views

    private let advertiserLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let callToActionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 14)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.isUserInteractionEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Init & Setup

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Assign GAD views
        self.mediaView = myMediaView
        self.headlineView = headlineLabel
        self.advertiserView = advertiserLabel
        self.bodyView = bodyLabel
        self.callToActionView = callToActionButton

        // Media aspect ratio constraint
        NSLayoutConstraint.activate([
            myMediaView.widthAnchor.constraint(
                equalTo: myMediaView.heightAnchor,
                multiplier: 16 / 9
            )
        ])

        // Left content stack
        let leftStack = UIStackView(arrangedSubviews: [
            headlineLabel,
            advertiserLabel,
            bodyLabel,
            callToActionButton,
        ])
        leftStack.axis = .vertical
        leftStack.spacing = 4
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        leftStack.layoutMargins = UIEdgeInsets(
            top: 8,
            left: 0,
            bottom: 8,
            right: 8
        )
        leftStack.isLayoutMarginsRelativeArrangement = true

        // Main horizontal stack
        let contentStack = UIStackView(arrangedSubviews: [
            myMediaView, leftStack,
        ])
        contentStack.axis = .horizontal
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.alignment = .top
        contentStack.distribution = .fill

        addSubview(contentStack)
        addSubview(adTag)

        // Constraints for content stack
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // Constraints for AD tag
        NSLayoutConstraint.activate([
            adTag.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            adTag.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            adTag.widthAnchor.constraint(greaterThanOrEqualToConstant: 25),
            adTag.heightAnchor.constraint(equalToConstant: 15),
        ])
    }
}

// [START create_native_ad_view]
private struct NativeAdViewContainer: UIViewRepresentable {
    typealias UIViewType = NativeAdView

    // Observer to update the UIView when the native ad value changes.
    @ObservedObject var nativeViewModel: NativeAdViewModel

    func makeUIView(context: Context) -> NativeAdView {
        return
            Bundle.main.loadNibNamed(
                "SmallTemplateView",
                owner: nil,
                options: nil
            )?.first as! NativeAdView
    }

    func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
        guard let nativeAd = nativeViewModel.nativeAd else { return }

        // Each UI property is configurable using your native ad.
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline

        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent

        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body

        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image

        (nativeAdView.starRatingView as? UIImageView)?.image = imageOfStars(
            from: nativeAd.starRating
        )

        (nativeAdView.storeView as? UILabel)?.text = nativeAd.store

        (nativeAdView.priceView as? UILabel)?.text = nativeAd.price

        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser

        (nativeAdView.callToActionView as? UIButton)?.setTitle(
            nativeAd.callToAction,
            for: .normal
        )

        // For the SDK to process touch events properly, user interaction should be disabled.
        nativeAdView.callToActionView?.isUserInteractionEnabled = false

        // Associate the native ad view with the native ad object. This is required to make the ad
        // clickable.
        // Note: this should always be done after populating the ad views.
        nativeAdView.nativeAd = nativeAd
    }
    // [END create_native_ad_view]

    private func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
        guard let rating = starRating?.doubleValue else {
            return nil
        }
        if rating >= 5 {
            return UIImage(named: "stars_5")
        } else if rating >= 4.5 {
            return UIImage(named: "stars_4_5")
        } else if rating >= 4 {
            return UIImage(named: "stars_4")
        } else if rating >= 3.5 {
            return UIImage(named: "stars_3_5")
        } else {
            return nil
        }
    }
}

//

public class NativeAdBannerView: NativeAdView {

    private let adTag: UILabel = {
        let label = UILabel()
        label.text = "AD"
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = .orange
        label.layer.cornerRadius = 2
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.widthAnchor.constraint(equalToConstant: 20).isActive = true
        return label
    }()

    private let headlineLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 1
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        imageView.heightAnchor.constraint(
            equalTo: imageView.widthAnchor,
            multiplier: 1
        ).isActive = true
        return imageView
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.headlineView = headlineLabel
        self.iconView = iconImageView
        self.bodyView = bodyLabel

        let headerStack = UIStackView(arrangedSubviews: [headlineLabel, adTag])
        headerStack.axis = .horizontal
        headerStack.spacing = 6
        headerStack.alignment = .center

        let leftStack = UIStackView(arrangedSubviews: [headerStack, bodyLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 4

        let mainStack = UIStackView(arrangedSubviews: [
            leftStack, iconImageView,
        ])
        mainStack.axis = .horizontal
        mainStack.spacing = 8
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 8
            ),
            mainStack.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -8
            ),
            mainStack.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -8
            ),
        ])
    }
}
