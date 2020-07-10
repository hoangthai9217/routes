//
//  TravelMode.swift
//  GapoRoutes
//
//  Created by peanut36k on 10/7/20.
//  Copyright © 2020 peanut36k. All rights reserved.
//

import Foundation

enum TravelMode: String {
    case driving = "driving"
    case walking = "walking"
    case bicycling = "bicycling"
    case transit = "transit"
    
    var parameterString: String {
        return self.rawValue
    }
}
