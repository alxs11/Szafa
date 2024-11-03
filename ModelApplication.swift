//
//  ModelApplication.swift
//  MyProject-CSE335
//
//  Created by Alexis Urias on 4/4/24.
//

import Foundation

struct User {
    var firstName:String
    var lastName: String
    var email: String
    var password: String
    var uid: String
    
    init(firstName: String, lastName: String, email: String, password: String, uid: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.password = password
        self.uid = uid
    }
      
}


struct ClothingItem: Hashable {
    var itemName: String
    var brand: String
    var category: String
    var color: String
    var size: String
    var price: Double
    var location: String
    var imageURL: String
}

struct Outfit {
    var outfitIDNumber: String
    var outfitStyle: String
    var items: [ClothingItem]
}
