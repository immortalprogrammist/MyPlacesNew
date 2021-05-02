//
//  MapViewController.swift
//  MyPlaces
//
//  Created by Nikita on 02.05.21.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    var place: Place!
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupPlacemark()
    }
    // закрываем карту и выгружаем ее из памяти
    @IBAction func closeVC() {
        dismiss(animated: true, completion: nil)
    }
    
    // маркер на карте
    private func setupPlacemark() {
        
        guard let location = place.location else { return }
        
        let geocoder = CLGeocoder() // отвечает за преобразование географических координат и названий. конвертирует адрес в координаты
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first // получили метку на карте
            
            let annotation = MKPointAnnotation()
            annotation.title = self.place.name
            annotation.subtitle = self.place.type
            
            guard let placemarkLocation = placemark?.location else { return }
            
            annotation.coordinate = placemarkLocation.coordinate
            
            self.mapView.showAnnotations([annotation], animated: true)
            self.mapView.selectAnnotation(annotation, animated: true)
        }
    }

}
