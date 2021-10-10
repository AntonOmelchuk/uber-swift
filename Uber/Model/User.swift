//
//  User.swift
//  Uber
//
//  Created by Anton Omelchuk on 30.09.2021.
//

import CoreLocation

enum AccountType: Int {
    case passenger
    case driver
}

struct User {
    let uid: String
    let fullName: String
    let email: String
    var accountType: AccountType!
    var location: CLLocation?
    
    var firstInitial: String { return String(fullName.prefix(1)) }

    init(uid: String, dictionary: [String: Any]) {
        self.uid = uid
        self.fullName = dictionary["fullName"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        
        if let index = dictionary["accountType"] as? Int {
            self.accountType = AccountType(rawValue: index)
        }
    }
}
