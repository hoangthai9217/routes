//
//  Constants.swift
//  GapoRoutes
//
//  Created by peanut36k on 10/7/20.
//  Copyright © 2020 peanut36k. All rights reserved.
//

import Foundation

enum StringConstants: String {
    case GoogleAPIKey = "AIzaSyD5kGt8erexBWZhCVkLHSjf7_lNufZzJKw"
    case GoogleDirectionAPIKey = "AIzaSyCYA9LKUpBhbxBwGEJw-m6Cum0zGGt4G_M"
    
    
}

extension StringConstants {
    var stringValue: String {
        return self.rawValue
    }
}
