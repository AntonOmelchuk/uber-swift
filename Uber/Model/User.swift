//
//  User.swift
//  Uber
//
//  Created by Anton Omelchuk on 30.09.2021.
//

struct User {
    let fullName: String
    let email: String
    let accountType: Int

    init(dictionary: [String: Any]) {
        self.fullName = dictionary["fullName"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.accountType = dictionary["accountType"] as? Int ?? 0
    }
}
