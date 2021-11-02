//
//  CachingManager.swift
//  WalkingTracker
//
//  Created by Mahmoud Abdelshafi on 02/11/2021.
//

import Foundation

class CachingManager {
    
    private init () {}
    private static var shared: CachingManager!
    
    static var trips = [Trip]()
    
    static func sharedInstance() -> CachingManager {
        if shared != nil {
            return shared
        } else {
            shared = CachingManager()
            return shared
        }
    }
    
}
