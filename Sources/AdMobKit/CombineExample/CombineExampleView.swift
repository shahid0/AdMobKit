//
//  AdsView.swift
//  AdMobKit
//
//  Created by mac on 28/07/2025.
//


import SwiftUI
import Combine

struct CombineAdsView: View {
    @StateObject var interstitialVM = InterstitialViewModel()
    @StateObject var rewardedVM = RewardedViewModel()
    @StateObject var rewardedInterstitalVM = RewardedInterstitialViewModel()
    @StateObject private var nativeViewModel = NativeAdViewModel(
        adUnitID: "ca-app-pub-3940256099942544/3986624511",
        requestInterval: 1
    )
    @StateObject var appOpenVM = AppOpenAdManager()
    @State private var bannerAdPhase = BannerLifecycleEvent.idle

    // Combine observer storage
    @State private var rewardedObserver: RewardedAdObserver?
    @State private var interstitialObserver: InterstitialAdObserver?

    var body: some View {
        VStack {
            Button("reload native") {
                nativeViewModel.refreshAd()
            }

            Button("hidden native") {
                hiddenNative.toggle()
            }

            if !nativeViewModel.isLoading && nativeViewModel.nativeAd != nil {
                GoogleNativeAdView(
                    nativeViewModel: nativeViewModel,
                    style: .card
                )
                .frame(height: 380)
                .padding(.horizontal)
            }

            BannerAdView(
                AdUnitID: "ca-app-pub-3940256099942544/2435281174",
                adPhase: $bannerAdPhase
            )
            .frame(height: bannerAdPhase.adLoadFailed ? 0 : 60)

            Button("show interstitial") {
                interstitialVM.showAd()
            }

            Button("show rewarded") {
                rewardedVM.showAd()
            }

            Button("show rewarded interstitial") {
                rewardedInterstitalVM.showAd()
            }

            Button("show appOpen") {
                appOpenVM.showAdIfAvailable()
            }
        }
        .onAppear {
            // ✅ 1. Combine Observer for Rewarded
            rewardedObserver = RewardedAdObserver(publisher: rewardedVM)

            // ✅ 2. Combine Observer for Interstitial
            interstitialObserver = InterstitialAdObserver(publisher: interstitialVM)
        }
        .onChange(of: bannerAdPhase) { newValue in
            // ✅ onChange Example
            print("[BannerAdView] Phase changed to: \(newValue)")
        }
        .task {
            await rewardedVM.loadAd(
                adUnitID: "ca-app-pub-3940256099942544/1712485313"
            )
        }
        .task {
            await rewardedInterstitalVM.loadAd(
                adUnitID: "ca-app-pub-3940256099942544/6978759866"
            )
        }
        .task {
            await appOpenVM.loadAd(
                adUnitID: "ca-app-pub-3940256099942544/5575463023"
            )
        }
        .task {
            await interstitialVM.loadAd(
                adUnitID: "ca-app-pub-3940256099942544/4411468910"
            )
        }
        .task {
            nativeViewModel.refreshAd()
        }
    }

    @State private var hiddenNative = false
}
