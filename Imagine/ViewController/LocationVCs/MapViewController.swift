//
//  MapViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.08.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import MapKit

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class Location {
    var title: String
    var coordinate: CLLocationCoordinate2D
    
    init(title: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
    }
}

class MapViewController: UIViewController, UIGestureRecognizerDelegate {

    let locationManager = CLLocationManager()
    let searchControllerStoryboardID = "LocationSearchTableViewController"
    
    var resultSearchController: UISearchController?
    
    var selectedPin: MKPlacemark?
    
    var location: Location? {
        didSet {
            guard let location = location else { return }

            chosenLocationLabel.text = location.title
            
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotation.title = location.title
            mapView.addAnnotation(annotation)
        }
    }
    
    var locationDelegate: ChoosenLocationDelegate?
    
    let mapView = MKMapView()
    let currentLocationButton = BaseButtonWithImage(image: Icons.location)
    let chosenLocationLabel = BaseLabel(text: Strings.chooseLocation, textAlignment: .center, backgroundColor: .secondarySystemBackground, cornerRadius: 8)
    let doneButton = BaseButtonWithText(text: Strings.done, cornerRadius: 8, backgroundColor: .secondarySystemBackground)
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupConstraints()
        setUpSearchController()
        setupMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isTranslucent = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.isTranslucent = false
    }
    
    // MARK: - Setup
    
    private func setupMap() {
        //Map
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(mapTapped(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 0.5
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        
        mapView.delegate = self
    }
    
    private func setupConstraints() {
        view.addSubview(mapView)
        view.addSubview(currentLocationButton)
        view.addSubview(chosenLocationLabel)
        view.addSubview(doneButton)
        
        mapView.fillSuperview()
        doneButton.constrain(bottom: view.bottomAnchor, trailing: view.trailingAnchor, paddingBottom: -75, paddingTrailing: -Constants.padding.standard, width: 75, height: 30)
        chosenLocationLabel.constrain(bottom: doneButton.topAnchor, trailing: doneButton.trailingAnchor, paddingBottom: -Constants.padding.standard, height: 30)
        chosenLocationLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 75).isActive = true
        
        currentLocationButton.constrain(bottom: chosenLocationLabel.topAnchor, trailing: doneButton.trailingAnchor, paddingBottom: -Constants.padding.standard, width: 28, height: 28)
        
        doneButton.addTarget(self, action: #selector(finishWithSelectedLocation), for: .touchUpInside)
        currentLocationButton.addTarget(self, action: #selector(requestCurrentLocation), for: .touchUpInside)
    }
    
    @objc func mapTapped(gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)

        // Add annotation:
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        getInformationForAnnotation(annotation: annotation)
    }
    
    private func getInformationForAnnotation(annotation: MKPointAnnotation) {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        
        //Remove old annotations:
        mapView.removeAnnotations(mapView.annotations)
        
        geoCoder.reverseGeocodeLocation(location) { placemarks, err -> Void in

            if let error = err {
                print("We have a map error: \(error.localizedDescription)")
            } else {
                if let placemarks = placemarks, let placemark = placemarks.first {
                    annotation.title = placemark.locality
                    self.addLocation(annotation: annotation)
                }
            }
        }
    }
    
    func addLocation(annotation: MKAnnotation) {
        if let title = annotation.title {
            if let title = title {
                self.chosenLocationLabel.text = title
                let location = Location(title: title, coordinate: annotation.coordinate)
                self.location = location
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    func setUpSearchController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let locationSearchTableVC = storyboard.instantiateViewController(withIdentifier: searchControllerStoryboardID) as? LocationSearchTableViewController else { return }
        
        locationSearchTableVC.mapView = mapView
        locationSearchTableVC.handleMapSearchDelegate = self
        resultSearchController = UISearchController(searchResultsController: locationSearchTableVC)
        
        guard let resultSearchController = resultSearchController else { return }

        resultSearchController.searchResultsUpdater = locationSearchTableVC
        resultSearchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        
        // Search Bar
        let searchBar = resultSearchController.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = Strings.mapSearchPlaceholder
        
        navigationItem.searchController = resultSearchController
    }
    
    @objc func requestCurrentLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    @objc func finishWithSelectedLocation() {
        if let location = location {
            locationDelegate?.gotLocation(location: location)
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation {
            self.addLocation(annotation: annotation)
        }
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
            
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        
        getInformationForAnnotation(annotation: annotation)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("We have a map error: \(error)")
    }
}

extension MapViewController: HandleMapSearch {
    
    func dropPinZoomIn(placemark:MKPlacemark){
        selectedPin = placemark
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
        let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        self.addLocation(annotation: annotation)
    }
}
