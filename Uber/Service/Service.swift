//
//  Service.swift
//  Uber
//
//  Created by Anton Omelchuk on 29.09.2021.
//

import Firebase

let DB_REF = Database.database(url: "https://uber-63066-default-rtdb.europe-west1.firebasedatabase.app").reference()
let REF_USERS = DB_REF.child("users")

struct Service {
    
    static let shared = Service()
    let currentUid = Auth.auth().currentUser?.uid
    
    func fetchUserData(completion: @escaping(String) -> Void) {
        REF_USERS.child(currentUid!).observeSingleEvent(of: .value) { snapshot in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            guard let fullName = dictionary["fullName"] as? String else { return }
            completion(fullName)
        }
    }
}
