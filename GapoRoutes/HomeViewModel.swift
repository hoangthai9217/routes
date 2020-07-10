//
//  HomeViewModel.swift
//  GapoRoutes
//
//  Created by peanut36k on 10/7/20.
//  Copyright © 2020 peanut36k. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

final class HomeViewModel {
    
    let mode = BehaviorRelay<TravelMode>(value: .driving)
    
    let selectStartingPoint = PublishRelay<Void>()
    let selectDestinationPoint = PublishRelay<Void>()
    
    init() {
        bind()
    }
    
    private func bind() {
        
    }
    
}
