//
//  HomeController.swift
//  uber-ride
//
//  Created by Gilang Aditya Rahman on 13/05/23.
//

import Firebase
import MapKit
import UIKit

private let reuseIdentifier = "LocationCell"
private let annotationIdentifer = "DriverAnnotation"

private enum ActionButtonConfiguration {
  case showMenu
  case dismissActionView

  init() {
    self = .showMenu
  }
}

private enum AnnotationType: String {
  case pickup
  case destination
}

protocol HomeControllerDelegate: AnyObject {
  func handleMenuToggle()
}

class HomeController: UIViewController {
  // MARK: - Properties

  private let mapView = MKMapView()
  private let locationManager = LocationHandler.shared.locationManager
  private let inputActionView = LocationInputActionView()
  private let locationInputView = LocationInputView()
  private let tableView = UITableView()
  private var searchResults = [MKPlacemark]()
  private final let locationInputViewHeight: CGFloat = 200
  private final let rideActionViewHeight: CGFloat = 300
  weak var delegate: HomeControllerDelegate?
  private var trip: Trip? {
    didSet {
      guard let user = user else { return }

      if user.accountType == .driver {
        guard let trip = trip else { return }
        let controller = PickupController(trip: trip)
        controller.delegate = self
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
      } else {}
    }
  }

  var user: User? {
    didSet {
      locationInputView.user = user
      if user?.accountType == .passenger {
        fetchDrivers()
        configureLocationInputActivationView()
        observeCurrentTrip()
      } else {
        observeTrips()
      }
    }
  }

  private let rideActionView = RideActionView()
  private var actionButtonConfig = ActionButtonConfiguration()
  private var route: MKRoute?

  private lazy var actionButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(named: "burger-menu")?.withRenderingMode(.alwaysOriginal), for: .normal)
    button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
    return button
  }()

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    checkIfUserIsLoggedIn()
    view.backgroundColor = .backgroundColor
    enableLocationServices()
    // signOut()
  }

  override func viewDidAppear(_: Bool) {
    // checkIfUserIsLoggedIn()
    view.backgroundColor = .backgroundColor
    enableLocationServices()
  }

  override func viewWillAppear(_: Bool) {
    guard let trip = trip else { return }
  }

  func checkIfUserIsLoggedIn() {
    if Auth.auth().currentUser?.uid == nil {
      DispatchQueue.main.async {
        let nav = UINavigationController(rootViewController: LoginController())
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
      }
    } else {
      configureUI()
    }
  }

  fileprivate func configureActionButton(config: ActionButtonConfiguration) {
    switch config {
    case .showMenu:
      actionButton.setImage(UIImage(named: "burger-menu")?.withRenderingMode(.alwaysOriginal), for: .normal)
      actionButtonConfig = .showMenu
    case .dismissActionView:
      actionButton.setImage(UIImage(named: "back-button")?.withRenderingMode(.alwaysOriginal), for: .normal)
      actionButtonConfig = .dismissActionView
    }
  }

  // MARK: - Passenger API

  func fetchDrivers() {
    guard let location = locationManager?.location else { return }
    PassengerService.shared.fetchDriver(location: location) { driver in
      guard let coordinate = driver.location?.coordinate else { return }
      let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
      var driverIsVisible: Bool {
        return self.mapView.annotations.contains(where: { annotation -> Bool in
          guard let driverAnno = annotation as? DriverAnnotation else { return false }
          if driverAnno.uid == driver.uid {
            driverAnno.updateAnnotationPosition(withCoordinate: coordinate)
            self.zoomForActiveTrip(withDriverUid: driver.uid)
            return true
          }
          return false
        })
      }

      if !driverIsVisible {
        self.mapView.addAnnotation(annotation)
      }
    }
  }

  // MARK: - Drivers API

  func observeTrips() {
    DriverService.shared.observeTrips { trip in
      self.trip = trip
    }
  }

  func observeCurrentTrip() {
    PassengerService.shared.observeCurrentTrip { trip in
      self.trip = trip
      guard let state = trip.state else { return }
      guard let driverUid = trip.driverUid else { return }

      switch state {
      case .requested:
        break
      case .accepted:
        self.shouldPresentLoadingView(false)
        self.removeAnnotationsAndOverlays()

        self.zoomForActiveTrip(withDriverUid: trip.driverUid ?? "")

        Service.shared.fetchUserData(uid: driverUid) { driver in
          self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: driver)
        }
      case .driverArrived:
        self.rideActionView.config = .driverArrived
      case .inProgress:
        self.rideActionView.config = .tripInProgress
      case .completed:

        PassengerService.shared.deleteTrip { _, _ in
          self.animateRideActionView(shouldShow: false)
          self.centerMapOnUserLocation()
          self.actionButtonConfig = .showMenu
          self.configureActionButton(config: .showMenu)
          self.inputActionView.alpha = 1
          self.presentAlertController(withTitle: "Trip Completed", message: "We hope you enjoyed your trip")
        }
      case .arrivedAtDestination:
        self.rideActionView.config = .endTrip
      }
    }
  }

  func startTrip() {
    guard let trip = trip else { return }
    Service.shared.updateTripState(trip: trip, state: .inProgress) { _, _ in
      self.rideActionView.config = .tripInProgress
      self.removeAnnotationsAndOverlays()
      self.mapView.addAnnotationAndSelect(forCoordinate: trip.destinationCoordinates!)

      let placemark = MKPlacemark(coordinate: trip.destinationCoordinates!)
      let mapItem = MKMapItem(placemark: placemark)
      self.setCustomRegion(withType: .destination, withCoordinate: trip.destinationCoordinates!)
      self.generatePolyline(toDestination: mapItem)

      self.mapView.zoomToFit(annotations: self.mapView.annotations)
    }
  }

  // MARK: - Helpers

  func configureUI() {
    configureMapView()
    configureRideActionView()

    view.addSubview(actionButton)
    actionButton.anchor(top: view.topAnchor, left: view.leftAnchor, paddingTop: 75, paddingLeft: 20, width: 38, height: 38)

    configureTableView()
  }

  func configureLocationInputActivationView() {
    view.addSubview(inputActionView)
    inputActionView.centerX(inView: view)
    inputActionView.setDimensions(height: 50, width: view.frame.width - 64)
    inputActionView.anchor(top: actionButton.bottomAnchor, paddingTop: 20)
    inputActionView.addShadow()
    inputActionView.alpha = 0
    inputActionView.delegate = self
    locationInputView.delegate = self

    UIView.animate(withDuration: 2) {
      self.inputActionView.alpha = 1
    }
  }

  func configureMapView() {
    view.addSubview(mapView)
    mapView.frame = view.frame

    mapView.showsUserLocation = true
    mapView.userTrackingMode = .follow
    mapView.delegate = self
  }

  func configureRideActionView() {
    view.addSubview(rideActionView)
    rideActionView.delegate = self
    rideActionView.frame = CGRect(x: 0, y: view.frame.height,
                                  width: view.frame.width, height: rideActionViewHeight)
  }

  func configureTableView() {
    tableView.delegate = self
    tableView.dataSource = self

    tableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdentifier)
    tableView.rowHeight = 60
    tableView.tableFooterView = UIView()

    let height = view.frame.height - locationInputViewHeight
    tableView.frame = CGRect(x: 0, y: view.frame.height,
                             width: view.frame.width, height: height)

    view.addSubview(tableView)
  }

  func configureLocationView() {
    view.addSubview(locationInputView)
    locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: locationInputViewHeight)
    inputActionView.alpha = 0
    UIView.animate(withDuration: 0.3, animations: {
      self.locationInputView.alpha = 1

    }) { _ in

      UIView.animate(withDuration: 0.3) {
        self.tableView.frame.origin.y = self.locationInputViewHeight
      }
    }
  }

  func dismissLocationView(completion: ((Bool) -> Void)? = nil) {
    UIView.animate(withDuration: 0.3, animations: {
      self.locationInputView.alpha = 0
      self.tableView.frame.origin.y = self.view.frame.height
      self.locationInputView.removeFromSuperview()

    }, completion: completion)
  }

  @objc func actionButtonPressed() {
    switch actionButtonConfig {
    case .showMenu:
      delegate?.handleMenuToggle()
    case .dismissActionView:
      removeAnnotationsAndOverlays()
      mapView.showAnnotations(mapView.annotations, animated: true)
      centerMapOnUserLocation()
      // mapView.zoomToFit(annotations: mapView.annotations)
      UIView.animate(withDuration: 0.3) {
        self.inputActionView.alpha = 1
        self.configureActionButton(config: .showMenu)
        self.animateRideActionView(shouldShow: false)
      }
    }
  }

  func animateRideActionView(shouldShow: Bool, destination: MKPlacemark? = nil, config: RideActionViewConfiguration? = nil,
                             user: User? = nil)
  {
    let yOrigin = shouldShow ? view.frame.height - rideActionViewHeight : view.frame.height

    UIView.animate(withDuration: 0.3) {
      self.rideActionView.frame.origin.y = yOrigin
    }

    if shouldShow {
      guard let config = config else { return }

      if let destination = destination {
        rideActionView.destination = destination
      }

      if let user = user {
        rideActionView.user = user
      }
      rideActionView.config = config
    }
  }
}

// MARK: - LocationServices

extension HomeController: CLLocationManagerDelegate {
  func locationManager(_: CLLocationManager, didStartMonitoringFor region: CLRegion) {
    if region.identifier == AnnotationType.pickup.rawValue {}

    if region.identifier == AnnotationType.destination.rawValue {}
  }

//  func locationManager(_: CLLocationManager, didEnterRegion _: CLRegion) {
//    print("Debug: driver did enter passenger region")
//
//    animateRideActionView(shouldShow: false)
//    guard let trip = trip else { return }
//    animateRideActionView(shouldShow: true, config: .pickupPassenger)
//    Service.shared.updateTripState(trip: trip, state: .driverArrived)
//  }

  func locationManager(_: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
    switch state {
    case .unknown:
      print("Unknown state for region \(region)")
    case .inside:
      print("Inside state for region \(region)")
      if region.identifier == AnnotationType.pickup.rawValue {
        Service.shared.fetchUserData(uid: trip?.passengerUid ?? "") { passenger in
          self.animateRideActionView(shouldShow: true, config: .pickupPassenger, user: passenger)
          guard let trip = self.trip else { return }
          Service.shared.updateTripState(trip: trip, state: .driverArrived) { _, _ in
            self.rideActionView.config = .pickupPassenger
          }
        }
      }

      if region.identifier == AnnotationType.destination.rawValue {
        Service.shared.fetchUserData(uid: trip?.passengerUid ?? "") { passenger in
          self.animateRideActionView(shouldShow: true, config: .pickupPassenger, user: passenger)
          guard let trip = self.trip else { return }
          Service.shared.updateTripState(trip: trip, state: .arrivedAtDestination) { _, _ in
            self.rideActionView.config = .endTrip
          }
        }
      }

    case .outside:
      print("outside state for region \(region)")
      Service.shared.fetchUserData(uid: trip?.passengerUid ?? "") { passenger in
        self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: passenger)
      }
    }
  }

  func enableLocationServices() {
    locationManager?.delegate = self
    switch CLLocationManager.authorizationStatus() {
    case .notDetermined:
      locationManager?.requestWhenInUseAuthorization()
    case .restricted, .denied:
      print("Debug : ")
    case .authorizedAlways:
      locationManager?.startUpdatingLocation()
      locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    case .authorizedWhenInUse:
      locationManager?.requestAlwaysAuthorization()
    @unknown default:
      break
    }
  }
}

// MARK: - LocationInputActionViewDelegate

extension HomeController: LocationInputActionViewDelegate {
  func presentLocationInputView() {
    inputActionView.alpha = 0
    configureLocationView()
  }
}

// MARK: - LocationInputViewDelegate

extension HomeController: LocationInputViewDelegate {
  func executeSearch(query: String) {
    searchBy(naturalLanguageQuery: query) { placemarks in
      self.searchResults = placemarks
      self.tableView.reloadData()
    }
  }

  func dismissLocationInputView() {
    dismissLocationView { _ in
      UIView.animate(withDuration: 0.3) {
        self.inputActionView.alpha = 1
      }
    }
  }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension HomeController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_: UITableView, titleForHeaderInSection _: Int) -> String? {
    return "Testing"
  }

  func numberOfSections(in _: UITableView) -> Int {
    return 2
  }

  func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
    return section == 0 ? 2 : searchResults.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
    if indexPath.section == 1 {
      cell.placemark = searchResults[indexPath.row]
    }

    return cell
  }

  func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    let selectedPlacemark = searchResults[indexPath.row]

    configureActionButton(config: .dismissActionView)
    let destination = MKMapItem(placemark: selectedPlacemark)
    generatePolyline(toDestination: destination)
    dismissLocationView { _ in
      self.mapView.addAnnotationAndSelect(forCoordinate: selectedPlacemark.coordinate)

//      self.mapView.annotations.forEach { annotation in
//        if let anno = annotation as? MKUserLocation {
//          annotations.append(anno)
//        }
//
//        if let anno = annotation as? MKPointAnnotation {
//          annotations.append(anno)
//        }
//      }

      let annotations = self.mapView.annotations.filter { !$0.isKind(of: DriverAnnotation.self) }
      self.mapView.zoomToFit(annotations: annotations)
      self.animateRideActionView(shouldShow: true, destination: selectedPlacemark, config: .requestRide)
    }
  }
}

// MARK: - Map Helper Function

private extension HomeController {
  func searchBy(naturalLanguageQuery: String, completion: @escaping ([MKPlacemark]) -> Void) {
    var results = [MKPlacemark]()

    let request = MKLocalSearch.Request()
    request.region = mapView.region
    request.naturalLanguageQuery = naturalLanguageQuery

    let search = MKLocalSearch(request: request)
    search.start { response, _ in
      guard let response = response else { return }

      response.mapItems.forEach { item in
        results.append(item.placemark)
      }

      completion(results)
    }
  }

  func generatePolyline(toDestination destination: MKMapItem) {
    let request = MKDirections.Request()
    request.source = MKMapItem.forCurrentLocation()
    request.destination = destination
    request.transportType = .automobile
    let directionRequest = MKDirections(request: request)
    directionRequest.calculate { response, _ in
      guard let response = response else { return }
      self.route = response.routes[0]
      guard let polyline = self.route?.polyline else { return }
      self.mapView.addOverlay(polyline)
    }
  }

  func removeAnnotationsAndOverlays() {
    mapView.annotations.forEach { annotation in
      if let anno = annotation as? MKPointAnnotation {
        mapView.removeAnnotation(anno)
      }
    }

    if mapView.overlays.count > 0 {
      mapView.removeOverlay(mapView.overlays[0])
    }
  }

  func centerMapOnUserLocation() {
    guard let coordinate = locationManager?.location?.coordinate else { return }
    let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
    mapView.setRegion(region, animated: true)
  }

  func setCustomRegion(withType type: AnnotationType, withCoordinate coordinates: CLLocationCoordinate2D) {
    let region = CLCircularRegion(center: coordinates, radius: 25, identifier: type.rawValue)
    region.notifyOnEntry = true
    region.notifyOnExit = true
    locationManager?.startMonitoring(for: region)
  }

  func zoomForActiveTrip(withDriverUid uid: String) {
    var annotations = [MKAnnotation]()
    mapView.annotations.forEach { annotation in
      if let anno = annotation as? DriverAnnotation {
        if anno.uid == uid {
          annotations.append(anno)
        }
      }
      if let userAnno = annotation as? MKUserLocation {
        annotations.append(userAnno)
      }
    }

    mapView.zoomToFit(annotations: annotations)
  }
}

// MARK: - MKMapViewDelegate

extension HomeController: MKMapViewDelegate {
  func mapView(_: MKMapView, didUpdate userLocation: MKUserLocation) {
    guard let user = user else { return }
    guard user.accountType == .driver else { return }
    guard let location = userLocation.location else { return }
    Service.shared.updateDriverLocation(location: location)
  }

  func mapView(_: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if let annotation = annotation as? DriverAnnotation {
      let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifer)
      view.image = UIImage(named: "driver")

      return view
    }

    return nil
  }

  func mapView(_: MKMapView, rendererFor _: MKOverlay) -> MKOverlayRenderer {
    if let route = route {
      let polyline = route.polyline
      let lineRenderer = MKPolylineRenderer(polyline: polyline)
      lineRenderer.strokeColor = .mainBlueTint
      lineRenderer.lineWidth = 3
      return lineRenderer
    }
    return MKOverlayRenderer()
  }
}

// MARK: - RideActionViewDelegate

extension HomeController: RideActionViewDelegate {
  func dropOffPassenger() {
    guard let trip = trip else { return }
    Service.shared.updateTripState(trip: trip, state: .completed) { _, _ in
      self.removeAnnotationsAndOverlays()
      self.centerMapOnUserLocation()
      self.animateRideActionView(shouldShow: false)
    }
  }

  func cancelTrip() {
    PassengerService.shared.deleteTrip { error, _ in
      if let error = error {
        print("Error deleting trip ...")
        return
      }
      self.animateRideActionView(shouldShow: false)
      self.removeAnnotationsAndOverlays()
      self.mapView.showAnnotations(self.mapView.annotations, animated: true)
      self.mapView.setCenter(self.mapView.userLocation.coordinate, animated: true)
      self.mapView.region.span.longitudeDelta = 0.03
      self.mapView.region.span.latitudeDelta = 0.03
      // mapView.zoomToFit(annotations: mapView.annotations)
      UIView.animate(withDuration: 0.3) {
        self.inputActionView.alpha = 1
        self.configureActionButton(config: .showMenu)
        self.animateRideActionView(shouldShow: false)
      }
    }
  }

  func uploadTrip(_ view: RideActionView) {
    guard let pickupCoordinates = locationManager?.location?.coordinate else { return }
    guard let destinationCoordinates = view.destination?.coordinate else { return }
    shouldPresentLoadingView(true, message: "Finding your driver ...")
    PassengerService.shared.uploadTrip(pickupCoordinates, destinationCoordinates, completion: { err, _ in
      if let error = err {
        print("Failed to upload \(error)")
      }

      UIView.animate(withDuration: 0.3) {
        self.rideActionView.frame.origin.y = self.view.frame.height
      }
    })
  }

  func pickupPassenger() {
    startTrip()
  }
}

// MARK: - PickupControllerDelegate

extension HomeController: PickupControllerDelegate {
  func didAcceptTrip(_ trip: Trip) {
    // trip?.state = .accepted
    self.trip = trip

    let anno = MKPointAnnotation()
    anno.coordinate = (trip.pickupCoordinates)!
    mapView.addAnnotation(anno)
    // mapView.selectAnnotation(anno, animated: true)
    mapView.addAnnotationAndSelect(forCoordinate: trip.pickupCoordinates!)

    setCustomRegion(withType: .pickup, withCoordinate: trip.pickupCoordinates!)

    let placemark = MKPlacemark(coordinate: (trip.pickupCoordinates)!)
    let mapItem = MKMapItem(placemark: placemark)
    generatePolyline(toDestination: mapItem)
    mapView.zoomToFit(annotations: mapView.annotations)

    DriverService.shared.observeTripCancelled(trip: trip) {
      self.removeAnnotationsAndOverlays()
      self.animateRideActionView(shouldShow: false)
      self.mapView.showAnnotations(self.mapView.annotations, animated: true)
      self.centerMapOnUserLocation()
      self.presentAlertController(withTitle: "Oops!", message: "The passenger has cancelled the trip")
    }

    dismiss(animated: true) {}
  }
}
