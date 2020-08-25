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
    
    var resultSearchController:UISearchController? = nil
    
    var selectedPin:MKPlacemark? = nil
    
    var location: Location?
    var locationDelegate: ChoosenLocationDelegate?
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var currentLocationButton: UIButton!
    @IBOutlet weak var choosenLocationLabel: UILabel!
    @IBOutlet weak var chooseCurrentLocationButton: DesignableButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Map
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(mapTapped(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 0.5
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        
        mapView.delegate = self
        
        if let location = location {
            choosenLocationLabel.text = location.title
            
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotation.title = location.title
            mapView.addAnnotation(annotation)
        } else {
            choosenLocationLabel.text = "Wähle einen Standort aus..."
        }
        
        setUpSearchController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isTranslucent = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.isTranslucent = false
    }
    
    @objc func mapTapped(gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)

        // Add annotation:
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        getInformationForAnnotation(annotation: annotation)
    }
    
    func getInformationForAnnotation(annotation: MKPointAnnotation) {   // Get String of city
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        
        //Remove old annotations:
        mapView.removeAnnotations(mapView.annotations)
        
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, err) -> Void in

            if let error = err {
                print("We have a map error: \(error.localizedDescription)")
            } else {
                if let placemarks = placemarks {
                    if placemarks.count > 0 {
                        let placemark = placemarks[0]
                        annotation.title = placemark.locality
                        self.addLocation(annotation: annotation)
                    }
                }
            }
        })
    }
    
    func addLocation(annotation: MKAnnotation) {
        if let title = annotation.title {
            if let title = title {
                self.choosenLocationLabel.text = title
                let location = Location(title: title, coordinate: annotation.coordinate)
                self.location = location
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    func setUpSearchController() {
        //Search
        let locationSearchTableVC = storyboard!.instantiateViewController(withIdentifier: searchControllerStoryboardID) as! LocationSearchTableViewController
        
        locationSearchTableVC.mapView = mapView
        locationSearchTableVC.handleMapSearchDelegate = self
        resultSearchController = UISearchController(searchResultsController: locationSearchTableVC)
        resultSearchController?.searchResultsUpdater = locationSearchTableVC
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        
        //searchBar
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        
        navigationItem.searchController = resultSearchController
    }
    
    @IBAction func getCurrentLocationTapped(_ sender: Any) {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    @IBAction func chooseSelectedLocationTapped(_ sender: Any) {
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
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("location: \(location)")
            
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            
            getInformationForAnnotation(annotation: annotation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("We have a map error: \(error)")
    }
}

extension MapViewController: HandleMapSearch {
    
    func dropPinZoomIn(placemark:MKPlacemark){
        // cache the pin
        selectedPin = placemark
        // clear existing pins
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
