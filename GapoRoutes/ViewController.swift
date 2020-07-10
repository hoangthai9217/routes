//
//  ViewController.swift
//  GapoRoutes
//
//  Created by peanut36k on 10/7/20.
//  Copyright © 2020 peanut36k. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import RxSwift
import RxCocoa
import RxRelay

enum TravelMode: String {
    case driving = "driving"
    case walking = "walking"
    case bicycling = "bicycling"
    case transit = "transit"
    
    var parameterString: String {
        return self.rawValue
    }
}

final class ViewController: UIViewController {
    
    // IBOutlets
    @IBOutlet private weak var mapContainerView: UIView!
    @IBOutlet private weak var drivingButton: UIButton!
    @IBOutlet private weak var transitButton: UIButton!
    @IBOutlet private weak var walkingButton: UIButton!
    @IBOutlet private weak var bicyclingButton: UIButton!
    
    private var viewModel: HomeViewModel!
    private let disposeBag = DisposeBag()
    private var mapView: GMSMapView?
    private let startMarker = GMSMarker()
    private let destinationMarker = GMSMarker()
    var a = 1
    
    override func awakeFromNib() {
        super.awakeFromNib()
        viewModel = HomeViewModel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMap()
        bind()
    }
    
    private func bind() {
        
        drivingButton.rx.tap
            .map({ TravelMode.driving })
            .bind(to: viewModel.mode)
            .disposed(by: disposeBag)
        
        transitButton.rx.tap
            .map({ TravelMode.transit })
            .bind(to: viewModel.mode)
            .disposed(by: disposeBag)
        
        walkingButton.rx.tap
            .map({ TravelMode.walking })
            .bind(to: viewModel.mode)
            .disposed(by: disposeBag)
        
        bicyclingButton.rx.tap
            .map({ TravelMode.bicycling })
            .bind(to: viewModel.mode)
            .disposed(by: disposeBag)
        
        viewModel.mode
            .asDriver(onErrorJustReturn: TravelMode.driving)
            .drive(onNext: { [weak self] mode in self?.updateModeUI(mode) })
            .disposed(by: disposeBag)
        
        viewModel.startingPoint
            .flatMap(Observable.from(optional: ))
            .map({ $0.coordinate })
            .asDriver(onErrorDriveWith: Driver.empty())
            .drive(onNext: { [weak self] place in self?.addStartPointMarker(place)})
            .disposed(by: disposeBag)
        
        viewModel.destinationPoint
            .flatMap(Observable.from(optional: ))
            .map({ $0.coordinate })
            .asDriver(onErrorDriveWith: Driver.empty())
            .drive(onNext: { [weak self] place in self?.addDestinationPointMarker(place)})
            .disposed(by: disposeBag)
        
        viewModel.drawPolylineRoute
            .asDriver(onErrorDriveWith: Driver.empty())
            .drive(onNext: { [weak self] points in self?.drawPolylineRoute(from: points.from, to: points.to)})
            .disposed(by: disposeBag)
        
        Observable.combineLatest(viewModel.mode, viewModel.drawPolylineRoute)
            .asDriver(onErrorDriveWith: Driver.empty())
            .drive(onNext: { [weak self] (mode, points) in self?.drawPolylineRoute(from: points.from, to: points.to, mode: mode) })
            .disposed(by: disposeBag)
        
    }
    
    private func addStartPointMarker(_ coordinate: CLLocationCoordinate2D) {
        startMarker.icon = UIImage(named: "location_pin_blue")!
        startMarker.position = coordinate
        startMarker.map = mapView
        mapView?.camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: 15)
    }
    
    private func addDestinationPointMarker(_ coordinate: CLLocationCoordinate2D) {
        destinationMarker.icon = UIImage(named: "location_pin")!
        destinationMarker.position = coordinate
        destinationMarker.map = mapView
        mapView?.camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: 15)
    }
    
    private func updateModeUI(_ mode: TravelMode) {
        drivingButton.tintColor = Colors.disabledButtonColor.uiColor
        transitButton.tintColor = Colors.disabledButtonColor.uiColor
        walkingButton.tintColor = Colors.disabledButtonColor.uiColor
        bicyclingButton.tintColor = Colors.disabledButtonColor.uiColor
        switch mode {
        case .bicycling: bicyclingButton.tintColor = Colors.primaryColor.uiColor
        case .driving:   drivingButton.tintColor = Colors.primaryColor.uiColor
        case .transit:   transitButton.tintColor = Colors.primaryColor.uiColor
        case .walking:   walkingButton.tintColor = Colors.primaryColor.uiColor
        }
    }
    
    private func configureMap() {
        let camera = GMSCameraPosition.camera(withLatitude: 21.0278, longitude: 105.8342, zoom: 10)
        mapView = GMSMapView.map(withFrame: mapContainerView.frame, camera: camera)
        guard let mapView = mapView else { return }
        mapContainerView.addSubview(mapView)
    }
    
    // MARK: - IBActions
    @IBAction private func selectStartingPoint() {
        searchAPlace()
            .asObservable()
            .bind(to: viewModel.startingPoint)
            .disposed(by: disposeBag)
    }
    
    @IBAction private func selectDestinationPoint() {
        searchAPlace()
            .asObservable()
            .bind(to: viewModel.destinationPoint)
            .disposed(by: disposeBag)
    }
    
    private var searchPlaceCoordinator: SearchPlaceCoordinator?
    private func searchAPlace() -> Observable<GMSPlace> {
        searchPlaceCoordinator = SearchPlaceCoordinator(context: self)
        return searchPlaceCoordinator!.start()
    }
    
//    private func search() {
//        let autocompleteController = GMSAutocompleteViewController()
//        autocompleteController.delegate = self
//        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) | UInt(GMSPlaceField.coordinate.rawValue))!
//        autocompleteController.placeFields = fields
//        present(autocompleteController, animated: true, completion: nil)
//    }
    
    func drawPolylineRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, mode: TravelMode = .driving) {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(source.latitude),\(source.longitude)&destination=\(destination.latitude),\(destination.longitude)&sensor=false&mode=\(mode.parameterString)&key=\(StringConstants.GoogleDirectionAPIKey.stringValue)"
        let url = URL(string: urlString)!
        let task = session.dataTask(with: url, completionHandler: { [weak self] (data, response, error) in
            guard let self = self else { return }
            if error != nil {
                print(error!.localizedDescription)
            } else {
                do {
                    if let json: [String: Any] = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] {
                        DispatchQueue.main.async {
                            let routes = json["routes"] as? NSArray
                            let routeOverviewPolyline:NSDictionary = (routes![0] as! NSDictionary).value(forKey: "overview_polyline") as! NSDictionary
                            let points = routeOverviewPolyline.object(forKey: "points")
                            let path = GMSPath.init(fromEncodedPath: points! as! String)
                            let polyline = GMSPolyline.init(path: path)
                            polyline.strokeWidth = 3
                            let bounds = GMSCoordinateBounds(path: path!)
                            self.mapView?.clear()
                            self.addStartPointMarker(source)
                            self.addDestinationPointMarker(destination)
                            self.mapView?.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 50.0))
                            polyline.map = self.mapView
                        }
                    }
                } catch {
                    print("error in JSONSerialization")
                }
            }
        })
        task.resume()
    }
    
}

//extension ViewController: GMSAutocompleteViewControllerDelegate {
//
//    // Handle the user's selection.
//    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
//
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
//        dismiss(animated: true, completion: nil)
//    }
//
//    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
//        print("Error: ", error.localizedDescription)
//    }
//
//    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
//        dismiss(animated: true, completion: nil)
//    }
//
//    // Turn the network activity indicator on and off again.
//    //    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
//    //        UIApplication.shared.isNetworkActivityIndicatorVisible = true
//    //    }
//    //
//    //    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
//    //        UIApplication.shared.isNetworkActivityIndicatorVisible = false
//    //    }
//
//}
