//
//  Category.swift
//  Anemone
//
//  Created by Ode on 7/16/25.
//

import Foundation
import SwiftData

@Model
class Category {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    init(name: String) {
        self.name = name
    }
    
    static let example: Category = Category(
        name: "Grocery"
    )
}
