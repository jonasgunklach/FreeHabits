//
//  Item.swift
//  FreeHabits
//
//  Created by Jonas Gunklach on 17.04.26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
