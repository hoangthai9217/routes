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
import GooglePlaces

class BaseViewModel {
    let disposeBag = DisposeBag()
}

final class HomeViewModel: BaseViewModel {
    
    let mode = BehaviorRelay<TravelMode>(value: .driving)
    
    let startingPoint = BehaviorRelay<GMSPlace?>(value: nil)
    let destinationPoint = BehaviorRelay<GMSPlace?>(value: nil)
    var drawPolylineRoute: Observable<(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D)> {
        let from = startingPoint.flatMap(Observable.from(optional: )).map({$0.coordinate})
        let to = destinationPoint.flatMap(Observable.from(optional: )).map({$0.coordinate})
        return Observable.combineLatest(from, to, resultSelector: { return (from: $0, to: $1) })
            .debounce(DispatchTimeInterval.milliseconds(200), scheduler: MainScheduler.instance)
    }
    
    let reversePoint = PublishRelay<Void>()
    
    override init() {
        super.init()
        bind()
    }
    
    private func bind() {
        reversePoint
            .subscribe(onNext: { [weak self] in
                let startingPointValue = self?.startingPoint.value
                let destinationPointValue = self?.destinationPoint.value
                self?.startingPoint.accept(destinationPointValue)
                self?.destinationPoint.accept(startingPointValue)
            })
            .disposed(by: disposeBag)
        
    }
    
}
