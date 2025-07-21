//
//  SwiftUIView.swift
//  AdMobKit
//
//  Created by mac on 21/07/2025.
//

import SwiftUI

struct AdsView: View {
    @StateObject var interstitialVM = InterstitialViewModel()
    @StateObject var rewardedVM = RewardedViewModel()
    @StateObject var rewardedInterstitalVM = RewardedInterstitialViewModel()
    @StateObject private var nativeViewModel = NativeAdViewModel(
        adUnitID: "ca-app-pub-3940256099942544/3986624511",
        requestInterval: 1
    )
    @State private var hiddenNative = false
    @State private var bannerAdLoadFail = false
    @StateObject var appOpenVM = AppOpenAdManager()
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
                .frame(height: 380)  // 250 ~ 300
                .padding(.horizontal)
            }

            BannerAdView(
                AdUnitID: "ca-app-pub-3940256099942544/2435281174",
                adLoadFailed: $bannerAdLoadFail
            )
            .frame(height: bannerAdLoadFail ? 0 : 60)

            Button(action: {
                interstitialVM.showAd()
            }) {
                Text("show interstial")
            }
            Button(action: {
                rewardedVM.showAd()
            }) {
                Text("show rewarded")
            }
            Button(action: {
                rewardedInterstitalVM.showAd()
            }) {
                Text("show rewarded interstial")
            }
            Button(action: {
                appOpenVM.showAdIfAvailable()
            }) {
                Text("show appOpen")
            }
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
}

#Preview {
    AdsView()
}
