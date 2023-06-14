//
//  Service.swift
//  uber-ride
//
//  Created by Gilang Aditya Rahman on 21/05/23.
//

import CoreLocation
import Firebase
import GeoFire

let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")
let REF_DRIVER_LOCATIONS = DB_REF.child("driver-location")
let REF_TRIPS = DB_REF.child("trips")

struct Service {
  static let shared = Service()

  func fetchUserData(uid: String, completion: @escaping (User) -> Void) {
    REF_USERS.child(uid).observeSingleEvent(of: .value) { snapshot in
      guard let dictionary = snapshot.value as? [String: Any] else { return }
      let uid = snapshot.key
      let user = User(uid: uid, dictionary: dictionary)
      completion(user)
    }
  }

  func fetchDriver(location: CLLocation, completion: @escaping (User) -> Void) {
    let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
    REF_DRIVER_LOCATIONS.observe(.value) { _ in
      geofire.query(at: location, withRadius: 50).observe(.keyEntered, with: { uid, location in
        self.fetchUserData(uid: uid) { user in
          var driver = user
          driver.location = location
          completion(driver)
        }
      })
    }
  }

  func uploadTrip(_ pickupCoordinates: CLLocationCoordinate2D,
                  _ destinationCoordinates: CLLocationCoordinate2D,
                  completion: @escaping (Error?, DatabaseReference) -> Void)
  {
    guard let uid = Auth.auth().currentUser?.uid else { return }
    let pickupArray = [pickupCoordinates.latitude, pickupCoordinates.longitude]
    let destinationArray = [destinationCoordinates.latitude, destinationCoordinates.longitude]

    let values = ["pickupCoordinates": pickupArray,
                  "destinationCoordinates": destinationArray,
                  "state": TripState.requested.rawValue] as [String: Any]

    REF_TRIPS.child(uid).updateChildValues(values, withCompletionBlock: completion)
  }
}
