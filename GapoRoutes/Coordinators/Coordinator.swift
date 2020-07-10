//
//  Coordinator.swift
//  GapoRoutes
//
//  Created by peanut36k on 10/7/20.
//  Copyright © 2020 peanut36k. All rights reserved.
//

import Foundation
import GooglePlaces
import RxSwift
import RxRelay

final class SearchPlaceCoordinator: NSObject {
    
    private let context: UIViewController
    private let result = PublishRelay<GMSPlace>()
    private let disposeBag = DisposeBag()
    
    init(context: UIViewController) {
        self.context = context
//        result.disposed(by: disposeBag)
    }
    
    func start() -> Observable<GMSPlace> {
        let autocompleteViewController = GMSAutocompleteViewController()
        autocompleteViewController.delegate = self
        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) | UInt(GMSPlaceField.coordinate.rawValue))!
        autocompleteViewController.placeFields = fields
        context.present(autocompleteViewController, animated: true, completion: nil)
        return result.asObservable()
    }
}

extension SearchPlaceCoordinator: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
//        if (a == 1) {
//            startMarker.icon = UIImage(named: "location_pin_blue")!
//            startMarker.position = place.coordinate
//            startMarker.title = place.name
//            startMarker.map = mapView
//
//            mapView?.camera = GMSCameraPosition.camera(withTarget: place.coordinate, zoom: 15)
//            mapView?.clear()
//        } else {
//            destinationMarker.icon = UIImage(named: "location_pin")!
//            destinationMarker.position = place.coordinate
//            destinationMarker.title = place.name
//            destinationMarker.map = mapView
//
//            drawPolylineRoute(from: startMarker.position, to: destinationMarker.position)
//        }
        result.accept(place)
//        result.onCompleted()
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
//        result.
        viewController.dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    //    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
    //        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    //    }
    //
    //    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
    //        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    //    }
    
}
