//
//  Driver.swift
//  Uber
//
//  Created by Anton Omelchuk on 01.10.2021.
//

import MapKit

class DriverAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var uid: String
    
    init(uid: String, coordinate: CLLocationCoordinate2D) {
        self.uid = uid
        self.coordinate = coordinate
    }
    
}
