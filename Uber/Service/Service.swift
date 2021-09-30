//
//  Service.swift
//  Uber
//
//  Created by Anton Omelchuk on 29.09.2021.
//

import Firebase

let DB_REF = Database.database(url: "https://uber-63066-default-rtdb.europe-west1.firebasedatabase.app").reference()
let REF_USERS = DB_REF.child("users")
let REF_DRIVER_LOCATIONS = DB_REF.child("driver-locations")

struct Service {
    
    static let shared = Service()
    
    func fetchUserData(completion: @escaping(User) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }

        REF_USERS.child(currentUid).observeSingleEvent(of: .value) { snapshot in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let user = User(dictionary: dictionary)
            
            completion(user)
        }
    }
}