//
//  Constants.swift
//  GapoRoutes
//
//  Created by peanut36k on 10/7/20.
//  Copyright © 2020 peanut36k. All rights reserved.
//

import Foundation
import UIKit

enum StringConstants: String {
    case GoogleAPIKey = ""
    
    var stringValue: String {
        return self.rawValue
    }
}

enum Colors {
    case primaryColor
    case disabledButtonColor
    
    var uiColor: UIColor {
        switch self {
        case .primaryColor:
            return UIColor.systemBlue
        case .disabledButtonColor:
            return UIColor.systemBlue.withAlphaComponent(0.3)
        }
    }
}
