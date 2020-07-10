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
    
//    let selectStartingPoint = PublishRelay<Void>()
//    let selectDestinationPoint = PublishRelay<Void>()
    
    let startingPoint = BehaviorRelay<GMSPlace?>(value: nil)
    let destinationPoint = BehaviorRelay<GMSPlace?>(value: nil)
    var drawPolylineRoute: Observable<(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D)> {
        let from = startingPoint.flatMap(Observable.from(optional: )).map({$0.coordinate})
        let to = destinationPoint.flatMap(Observable.from(optional: )).map({$0.coordinate})
        return Observable.combineLatest(from, to, resultSelector: { return (from: $0, to: $1) })
    }
    
    //    let searchAPlace = PublishSubject<Void>()
    
    private func bind() {
//        selectStartingPoint
//            .asObservable()
//            .subscribe(onNext: {
//
//            })
//            .disposed(by: disposeBag)
    }
    
}
