//
//  InterstitialAdObserver.swift
//  AdMobKit
//
//  Created by mac on 28/07/2025.
//


import Combine
import Foundation

public final class InterstitialAdObserver {
    private var cancellables = Set<AnyCancellable>()

    public init(publisher: InterstitialViewModel) {
        publisher.$adPhase
            .sink { phase in
                print("[InterstitialAdObserver] Phase changed to: \(phase)")
            }
            .store(in: &cancellables)
    }
}
