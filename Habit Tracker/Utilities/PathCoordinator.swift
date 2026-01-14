//
//  PathCoordinator.swift
//  Practice
//
//  Created by Robert Farley on 21/12/2025.
//

import Foundation
import SwiftUI

@Observable
class NavigationCoordinator {
    
    var path = NavigationPath()
    
    func popToRoot() {
        path = NavigationPath()
    }
    
    func goBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
}
