//
//  LocationHandler.swift
//  uber-ride
//
//  Created by Gilang Aditya Rahman on 21/05/23.
//

import Foundation
import CoreLocation

class LocationHandler: NSObject, CLLocationManagerDelegate {
  static let shared = LocationHandler()
  
  var locationManager: CLLocationManager!
  var location: CLLocation?
  
  override init() {
    super.init()
    locationManager = CLLocationManager()
    locationManager.delegate = self
  }
  
  func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    if status == .authorizedWhenInUse {
      locationManager.requestAlwaysAuthorization()
    }
  }
}
