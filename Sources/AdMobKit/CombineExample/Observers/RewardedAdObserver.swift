//
//  RewardedAdObserver.swift
//  AdMobKit
//
//  Created by mac on 28/07/2025.
//


import Combine
import Foundation

public final class RewardedAdObserver {
    private var cancellables = Set<AnyCancellable>()

    public init(publisher: RewardedViewModel) {
        publisher.$adPhase
            .sink { phase in
                switch phase {
                case .reward(let amount):
                    publisher.addCoins(amount)
                    print("[RewardedAdObserver] Earned \(amount) coins. Total: \(publisher.coins)")
                default:
                    print("[RewardedAdObserver] Phase changed to: \(phase)")
                }
            }
            .store(in: &cancellables)
    }
}
