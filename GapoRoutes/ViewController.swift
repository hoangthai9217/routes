//
//  ViewController.swift
//  GapoRoutes
//
//  Created by peanut36k on 10/7/20.
//  Copyright © 2020 peanut36k. All rights reserved.
//

import UIKit
import GoogleMaps

final class ViewController: UIViewController {
    
    @IBOutlet private weak var mapContainerView: UIView!
    
    private var mapView: GMSMapView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMap()
    }
    
    private func configureMap() {
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        mapView = GMSMapView.map(withFrame: mapContainerView.frame, camera: camera)
        guard let mapView = mapView else { return }
        mapContainerView.addSubview(mapView)

        // Creates a marker in the center of the map.
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: -33.86, longitude: 151.20)
        marker.title = "Sydney"
        marker.snippet = "Australia"
        marker.map = mapView
    }


}

