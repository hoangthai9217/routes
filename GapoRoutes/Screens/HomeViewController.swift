//
//  HomeViewController.swift
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

final class HomeViewController: UIViewController {
    
    // IBOutlets
    @IBOutlet private weak var mapView: GMSMapView!
    @IBOutlet private weak var drivingButton: UIButton!
    @IBOutlet private weak var transitButton: UIButton!
    @IBOutlet private weak var walkingButton: UIButton!
    @IBOutlet private weak var bicyclingButton: UIButton!
    
    @IBOutlet private weak var startPointTextField: UITextField!
    @IBOutlet private weak var destinationPointTextField: UITextField!
    
    private var viewModel: HomeViewModel!
    private let disposeBag = DisposeBag()
    private let startMarker = GMSMarker()
    private let destinationMarker = GMSMarker()
    
    private let locationManager = CLLocationManager()
    
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
            .asDriver(onErrorDriveWith: Driver.empty())
            .drive(onNext: { [weak self] place in self?.addStartPointMarker(place, moveCamera: true)})
            .disposed(by: disposeBag)
        
        viewModel.destinationPoint
            .flatMap(Observable.from(optional: ))
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
    
    private func addMarkerToMap(marker: GMSMarker, place: GMSPlace, moveCamera: Bool = false) {
        marker.position = place.coordinate
        marker.title = place.name
        marker.map = mapView
        if moveCamera {
            mapView?.camera = GMSCameraPosition.camera(withTarget: place.coordinate, zoom: 15)
        }
    }
    
    private func addStartPointMarker(_ place: GMSPlace, moveCamera: Bool = false) {
        startMarker.icon = UIImage(named: "location_pin_blue")!
        addMarkerToMap(marker: startMarker, place: place, moveCamera: moveCamera)
        startPointTextField.text = place.name
    }
    
    private func addDestinationPointMarker(_ place: GMSPlace, moveCamera: Bool = false) {
        destinationMarker.icon = UIImage(named: "location_pin")!
        addMarkerToMap(marker: destinationMarker, place: place, moveCamera: moveCamera)
        destinationPointTextField.text = place.name
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
        mapView.camera = camera
        mapView.isMyLocationEnabled = true
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - IBActions
    @IBAction private func selectStartingPoint() {
        searchAPlace()
            .bind(to: viewModel.startingPoint)
            .disposed(by: disposeBag)
    }
    
    @IBAction private func selectDestinationPoint() {
        searchAPlace()
            .bind(to: viewModel.destinationPoint)
            .disposed(by: disposeBag)
    }
    
    @IBAction private func reversePoints() {
        viewModel.reversePoint.accept(())
    }
    
    @IBAction private func checkCurrentLocation() {
        locationManager.startUpdatingLocation()
    }
    
    private var searchPlaceCoordinator: SearchPlaceCoordinator?
    private func searchAPlace() -> Observable<GMSPlace> {
        searchPlaceCoordinator = SearchPlaceCoordinator(context: self)
        return searchPlaceCoordinator!.start()
    }
    
    private func drawPolylineRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, mode: TravelMode = .driving) {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(source.latitude),\(source.longitude)&destination=\(destination.latitude),\(destination.longitude)&sensor=false&mode=\(mode.parameterString)&key=\(StringConstants.GoogleDirectionAPIKey.stringValue)"
        let url = URL(string: urlString)!
        let task = session.dataTask(with: url, completionHandler: { [weak self] (data, response, error) in
            guard let self = self else { return }
            if error != nil {
                self.showNoRouteAlert()
            } else {
                do {
                    if let json: [String: Any] = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] {
                        DispatchQueue.main.async {
                            guard let routes = json["routes"] as? NSArray, routes.count > 0 else {
                                self.showNoRouteAlert()
                                return
                            }
                            let routeOverviewPolyline: NSDictionary = (routes[0] as! NSDictionary).value(forKey: "overview_polyline") as! NSDictionary
                            let points = routeOverviewPolyline.object(forKey: "points")
                            let path = GMSPath(fromEncodedPath: points! as! String)
                            let polyline = GMSPolyline(path: path)
                            polyline.strokeWidth = 6
                            let bounds = GMSCoordinateBounds(path: path!)
                            self.mapView?.clear()
                            if let startPoint = self.viewModel.startingPoint.value, let destinationPoint = self.viewModel.destinationPoint.value {
                                self.addStartPointMarker(startPoint)
                                self.addDestinationPointMarker(destinationPoint)
                            }
                            self.mapView?.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 50.0))
                            polyline.map = self.mapView
                        }
                    }
                } catch {
                    self.showNoRouteAlert()
                }
            }
        })
        task.resume()
    }
    
    private func showNoRouteAlert() {
        showPopUp(title: "Error", message: "No routes found!")
    }
    
    private func showPopUp(title: String?, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }
    
}

extension HomeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        let camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: 17.0)
        mapView.animate(to: camera)
        locationManager.stopUpdatingLocation()
    }
}
