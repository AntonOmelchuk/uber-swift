//
//  HomeController.swift
//  Uber
//
//  Created by Anton Omelchuk on 26.09.2021.
//

import UIKit
import Firebase
import MapKit

private let resuseIdentifier = "LocationCell"
private let annotationIdentifier = "DriverAnnotation"
private enum ActionButtonConfiguration {
    case showMenu
    case dissmisActionView
    
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
    
    private let inputActivationView = LocationInputActivationView()
    private let locationInputView = LocationInputView()
    private let tableView = UITableView()
    private let rideActionView = RideActionView()
    private var searchResults = [MKPlacemark]()
    private final let locationInputViewHeight: CGFloat = 200
    private final let rideActionViewHeight: CGFloat = 300
    private var route: MKRoute?
    
    weak var delegate: HomeControllerDelegate?
    
    var user: User? {
        didSet {
            locationInputView.titleLabel.text = user?.fullName
            
            if user?.accountType == .passenger {
                fetchDrivers()
                configureLocationInputActivationView()
                observeCurrentTrip()
            } else {
                observeTrips()
            }
        }
    }
    
    private var trip: Trip? {
        didSet {
            guard let user = user else { return }
            
            if user.accountType == .driver {
                guard let trip = trip else { return }
                let controller = PickupController(trip: trip)
                controller.delegate = self
                controller.modalPresentationStyle = .fullScreen
                self.present(controller, animated: true, completion: nil)
            } else {
                print("DEBUG: Show ride action view for accepted trip...")
            }
        }
    }
    
    private var actionButtonConfig = ActionButtonConfiguration()
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        
        return button
    }()
    
    // MARK: - Selectors
    
    @objc func actionButtonPressed() {
        switch actionButtonConfig {
        case .showMenu:
            delegate?.handleMenuToggle()
        case .dissmisActionView:
            removeAnnotationsAndOverlays()
            mapView.showAnnotations(mapView.annotations, animated: true)
            
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
                self.configureActionButton(config: .showMenu)
                self.animateRideActionView(shouldShow: false)
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        enableLocationServices()
        configureUI()
    }
    
    // MARK: - Shared API
    
    func fetchUserData() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        Service.shared.fetchUserData(uid: currentUid) { user in
            self.user = user
        }
    }
    
    // MARK: - Passenger API
    
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
                self.zoomForActiveTrip(withDriverUid: driverUid)
                
                Service.shared.fetchUserData(uid: driverUid) { driver in
                    self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: driver)
                }
            case .driverArrived:
                self.rideActionView.config = .driverArrived
            case .inProgress:
                break
            case .arrivedAtDestination:
                self.rideActionView.config = .endTrip
            case .completed:
                PassengerService.shared.deleteTrip { (error, ref) in
                    self.animateRideActionView(shouldShow: false)
                    self.centerMapOnUserLocation()
                    self.configureActionButton(config: .showMenu)
                    self.inputActivationView.alpha = 1
                    self.presentAlerController(withTitle: "Trip Completed", withMessage: "We hope you enjoyed your trip")
                }
            }
        }
    }
    
    func startTrip() {
        guard let trip = self.trip else { return }
        DriverService.shared.updateTripState(trip: trip, state: .inProgress) { (error, ref) in
            self.rideActionView.config = .tripInProgress
            self.removeAnnotationsAndOverlays()
            self.mapView.addAnnotationAndSelect(forCoordinate: trip.destinationCoordinates)
            
            let placemark = MKPlacemark(coordinate: trip.destinationCoordinates)
            let mapItem = MKMapItem(placemark: placemark)
            
            self.setCustomRegion(withType: .destination, coordinates: trip.destinationCoordinates)
            self.generatePolyline(toDestination: mapItem)
            
            self.mapView.zoomToFit(annotations: self.mapView.annotations)
        }
    }
    
    func fetchDrivers() {
        guard let location = locationManager?.location else { return }
        PassengerService.shared.fetchDrivers(location: location) { driver in
            guard let coordinate = driver.location?.coordinate else { return }
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
            
            var driverIsVisible: Bool {
                return self.mapView.annotations.contains { annotation in
                    guard let driverAnnotation = annotation as? DriverAnnotation else { return false }
                    if driverAnnotation.uid == driver.uid {
                        driverAnnotation.updateAnnotationPosition(withCoordinate: coordinate)
                        self.zoomForActiveTrip(withDriverUid: driver.uid)
                        return true
                    }
                    return false
                }
            }
            
            if !driverIsVisible {
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    // MARK: - Driver API
    
    func observeTrips() {
        DriverService.shared.observeTrips { trip in
            self.trip = trip
        }
    }
    
    func observerCancelTrip(trip: Trip) {
        DriverService.shared.observeTripCancel(trip: trip) {
            self.removeAnnotationsAndOverlays()
            self.animateRideActionView(shouldShow: false)
            self.centerMapOnUserLocation()
            self.presentAlerController(withTitle: "Oops!", withMessage: "The passenger has decided to cancel this ride. Press OK to continue.")
        }

    }
    
    // MARK: - Helper Functions
    
    func configure() {
        configureUI()
    }
    
    func configureUI() {
        configureMapView()
        configureRideActionView()
        
        view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingTop: 16, paddingLeft: 20, width: 30, height: 30)
        
        configureTableView()
    }
    
    func configureLocationInputActivationView() {
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDemensions(height: 50, width: view.frame.width - 64)
        inputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop: 32)
        inputActivationView.alpha = 0
        inputActivationView.delegate = self
        
        UIView.animate(withDuration: 2) {
            self.inputActivationView.alpha = 1
        }
    }
    
    func configureMapView() {
        view.addSubview(mapView)
        mapView.frame = view.frame
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
    }
    
    func configureLocationInputView() {
        locationInputView.delegate = self
        view.addSubview(locationInputView)
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: locationInputViewHeight)
        locationInputView.alpha = 0
        
        UIView.animate(withDuration: 0.5, animations: {
            self.locationInputView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.tableView.frame.origin.y = self.locationInputViewHeight
            }
        }
    }
    
    func configureRideActionView() {
        view.addSubview(rideActionView)
        rideActionView.delegate = self
        rideActionView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: rideActionViewHeight)
    }
    
    func animateRideActionView(shouldShow: Bool, destination: MKPlacemark? = nil, config: RideActionViewConfiguration? = nil, user: User? = nil) {
        let viewHeight = self.view.frame.height
        let yOrigin = shouldShow ? viewHeight - self.rideActionViewHeight : viewHeight
        
        UIView.animate(withDuration: 0.3) {
            self.rideActionView.frame.origin.y = yOrigin
        }
        
        if shouldShow {
            guard let config = config else { return }
           
            if let destination = destination {
                self.rideActionView.destination = destination
            }
            
            if let user = user {
                rideActionView.user = user
            }
            
            rideActionView.config = config
        }
    }
    
    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(LocationCell.self, forCellReuseIdentifier: resuseIdentifier)
        tableView.rowHeight = 60
        tableView.tableFooterView = UIView()
        let height = view.frame.height - locationInputViewHeight
        tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
        
        view.addSubview(tableView)
    }
    
    func dismissLocationView(completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
            self.locationInputView.removeFromSuperview()
        }, completion: completion)
    }
    
    fileprivate func configureActionButton(config: ActionButtonConfiguration) {
        switch config {
        case .showMenu:
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
        case .dissmisActionView:
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp-1").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .dissmisActionView
        }
    }
}

// MARK: - MapView Helper Functions

private extension HomeController {
    func searchBy(naturalLanguageQuery: String, completion: @escaping([MKPlacemark]) -> Void) {
        var results = [MKPlacemark]()
        
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
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
        directionRequest.calculate { (response, error) in
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
    
    func setCustomRegion(withType type: AnnotationType, coordinates: CLLocationCoordinate2D) {
        let region = CLCircularRegion(center: coordinates, radius: 25, identifier: type.rawValue)
        locationManager?.startMonitoring(for: region)
        
        print("DEBUG: Did set region \(region)")
    }
    
    func zoomForActiveTrip(withDriverUid uid: String) {
        var annotations = [MKAnnotation]()
        
        self.mapView.annotations.forEach { (annotation) in
            if let anno = annotation as? DriverAnnotation {
                if anno.uid == uid {
                    annotations.append(anno)
                }
            }
            
            if let userAnno = annotation as? MKUserLocation {
                annotations.append(userAnno)
            }
        }
        
        self.mapView.zoomToFit(annotations: annotations)
    }
}

// MARK: - MKMapViewDelegate

extension HomeController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let user = self.user else { return }
        guard user.accountType == .driver else { return }
        guard let location = userLocation.location else { return }
        
        DriverService.shared.updateDriverLocation(location: location)
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            view.image = #imageLiteral(resourceName: "chevron-sign-to-right")
            return view
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = self.route {
            let polyline = route.polyline
            let lineRender = MKPolylineRenderer(overlay: polyline)
            lineRender.strokeColor = .mainBlueTint
            lineRender.lineWidth = 3
            
            return lineRender
        }
        
        return MKOverlayRenderer()
    }
}

// MARK: - CLLocationManagerDelegate

extension HomeController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if region.identifier == AnnotationType.pickup.rawValue {
            
        }
        
        if region.identifier == AnnotationType.destination.rawValue {
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let trip = self.trip else { return }
        
        if region.identifier == AnnotationType.pickup.rawValue {
            DriverService.shared.updateTripState(trip: trip, state: .driverArrived) { (error, ref) in
                self.rideActionView.config = .pickupPassenger
            }
        }
        
        if region.identifier == AnnotationType.destination.rawValue {
            DriverService.shared.updateTripState(trip: trip, state: .arrivedAtDestination) { (error, ref) in
                self.rideActionView.config = .endTrip
            }
        }
    }
    
    func enableLocationServices() {
        locationManager?.delegate = self
        switch locationManager?.authorizationStatus {
        case .notDetermined:
            locationManager?.requestWhenInUseAuthorization()
        case .denied, .restricted:
            break
        case .authorizedAlways:
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            locationManager?.requestAlwaysAuthorization()
        default:
            break
        }

    }
}

// MARK: - LocationInputActivetaViewDelegate

extension HomeController: LocationInputActivetaViewDelegate {
    func presentLocationInputView() {
        inputActivationView.alpha = 0
        configureLocationInputView()
    }
}

// MARK: - LocationInputViewDelegate

extension HomeController: LocationInputViewDelegate {
    func executeSearch(query: String) {
        searchBy(naturalLanguageQuery: query) { results in
            self.searchResults = results
            self.tableView.reloadData()
        }
    }
    
    func dismissLocationInputView() {
        dismissLocationView { _ in
            UIView.animate(withDuration: 0.3, animations: {
                self.inputActivationView.alpha = 1
            })
        }
    }
}

// MARK: - UITableViewDelegate/UITableViewDataSource

extension HomeController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Result"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: resuseIdentifier, for: indexPath) as! LocationCell
        
        cell.placemark = searchResults[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { 
        let selectedPlacemark = searchResults[indexPath.row]
        
        configureActionButton(config: .dissmisActionView)
        
        let destination = MKMapItem(placemark: selectedPlacemark)
        generatePolyline(toDestination: destination)
        
        dismissLocationView { _ in
            self.mapView.addAnnotationAndSelect(forCoordinate: selectedPlacemark.coordinate)
            
            let annotations = self.mapView.annotations.filter { !$0.isKind(of: DriverAnnotation.self) }
            
            self.mapView.zoomToFit(annotations: annotations)
            
            self.animateRideActionView(shouldShow: true, destination: selectedPlacemark, config: .requestRide)
        }
    }
}

// MARK: - RideActionViewDelegate

extension HomeController: RideActionViewDelegate {
    func uploadTrip(_ view: RideActionView) {
        guard let pickupCoordinates = locationManager?.location?.coordinate else { return }
        guard let destinationCoordinates = view.destination?.coordinate else { return }
        
        shouldPresentLoadingView(true, message: "Finding you a ride...")
        
        PassengerService.shared.uploadTrip(pickupCoordinates, destinationCoordinates) { (err, ref) in
            if let error = err {
                print("DEBUG: ERROR: \(error)")
                return
            }
            
            UIView.animate(withDuration: 0.3) {
                self.rideActionView.frame.origin.y = self.view.frame.height
            }
        }
    }
    
    func cancelTrip() {
        PassengerService.shared.deleteTrip { (error, ref) in
            if let error = error {
                print("DEBUG: Error cancel trip \(error.localizedDescription)")
                return
            }
            
            self.centerMapOnUserLocation()
            self.animateRideActionView(shouldShow: false)
            self.removeAnnotationsAndOverlays()
            
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
            
            self.inputActivationView.alpha = 1
        }
    }
    
    func pickupPassenger() {
        startTrip()
    }
    
    func dropOffPassenger() {
        guard let trip = self.trip else { return }
        DriverService.shared.updateTripState(trip: trip, state: .completed) { (error, ref) in
            self.removeAnnotationsAndOverlays()
            self.centerMapOnUserLocation()
            self.animateRideActionView(shouldShow: false)
        }
    }
}

// MARK: - PickupControllerDelegate

extension HomeController: PickupControllerDelegate {
    func didAcceptTrip(_ trip: Trip) {
        self.trip = trip
        
        self.mapView.addAnnotationAndSelect(forCoordinate: trip.pickupCoordinates)
        
        setCustomRegion(withType: .pickup, coordinates: trip.pickupCoordinates)
        
        let placemark = MKPlacemark(coordinate: trip.pickupCoordinates)
        let mapItem = MKMapItem(placemark: placemark)
        generatePolyline(toDestination: mapItem)
        
        mapView.zoomToFit(annotations: mapView.annotations)
        
        self.observerCancelTrip(trip: trip)
                
        self.dismiss(animated: true) {
            Service.shared.fetchUserData(uid: trip.passengerUid) { passenger in
                self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: passenger)
            }
        }
    }
}
