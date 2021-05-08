//
//  MapViewController.swift
//  MyPlaces
//
//  Created by Nikita on 02.05.21.
//

import UIKit
import MapKit
import CoreLocation

protocol MapViewControllerDelegate {
    
    func getAddress(address: String?)
}

class MapViewController: UIViewController {
    
    let mapManager = MapManager()
    var mapViewControllerDelegate: MapViewControllerDelegate?
    var place = Place()
    
    let annotationIndetifier = "annotationIndetifier"
    var incomeSegueIdentifier = ""
  
    var previousLocation: CLLocation? { // хранение предыдущего местоположения пользователя.
        didSet {
            mapManager.startTrackingUserLocation(
                for: mapView,
                and: previousLocation) { (currentLocation) in
                
                    self.previousLocation = currentLocation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.mapManager.showUserLocation(mapView: self.mapView)
                    }
            }
        }
    }
 
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapPinImage: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    
    
    override func viewDidLoad() {

        super.viewDidLoad()
        
        addressLabel.text = ""
        mapView.delegate = self
        setupMapView()
    }
    
    // MARK: IBActions
    
    // Перенапревление на местоположение пользователя
    @IBAction func centerViewInUserLocation() {
        mapManager.showUserLocation(mapView: mapView)
    }
    
    // закрываем карту и выгружаем ее из памяти
    @IBAction func closeVC() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goButtonPressed() {
        mapManager.getDirections(for: mapView) { (location) in
            self.previousLocation = location
        }
    }
    
    @IBAction func doneButtonPressed() {
        
        mapViewControllerDelegate?.getAddress(address: addressLabel.text) // передаем адрес в метод
        dismiss(animated: true, completion: nil) // закрываем VC
    }
    
    //
    private func setupMapView() {
        
        goButton.isHidden = true
        
        mapManager.checkLocationServices(mapView: mapView, segueIdentifier: incomeSegueIdentifier) {
            mapManager.locationManager.delegate = self
        }
        
        if incomeSegueIdentifier == "showPlace" {
            mapManager.setupPlacemark(place: place, mapView: mapView)
            mapPinImage.isHidden = true // крываем маркер, если переходим по сегвею showPlace
            addressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else { return nil } // убеждаемся, что аннотация не является текущим местоположением пользователя и не создаем аннотации для точки.
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIndetifier) as?
            MKPinAnnotationView // объект класса MKAnnotationView, а MKPinAnnotationView скастили для того, чтобы была видна булавочка на карте
        
        // Если на карте не окажется ни одного представления аннотации, которое мы могли переиспользовать, инициализируем объект новым значением
        if annotationView == nil {
            
            annotationView = MKPinAnnotationView(annotation: annotation,
                                                 reuseIdentifier: annotationIndetifier) // инициализация
            
            annotationView?.canShowCallout = true // отображаем в виде банера
        }
        
        // добавляем картинку на банер
        if let imageData = place.imageData { // извлекаем опционал
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50)) // !!! 50 поинтов высота банера !!!
            imageView.layer.cornerRadius = 10 // скруглили углы
            imageView.clipsToBounds = true // обрезали по границам
            imageView.image = UIImage(data: imageData) // достаем фото
            annotationView?.rightCalloutAccessoryView = imageView // разместили картинку справа на банере
        }
        
        return annotationView
    }
    
    // отображаем адрес, который находится в центре экрана
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // текущии координаты по центру отображаемой области
        let center = mapManager.getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        // возвращаем приближение к пользователю, после маштабирования карты
        if incomeSegueIdentifier == "showPlace" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.mapManager.showUserLocation(mapView: mapView)
            }
        }
        // освобождаем ресурсы связанные с геокодированием, делаем отмену отложенного запроса
        geocoder.cancelGeocode()
        
        // преобразовываем координаты в адрес
        geocoder.reverseGeocodeLocation(center) { (placemarks, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            // извлекаем массив меток
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first
            let streetName = placemark?.thoroughfare
            let buildNumber = placemark?.subThoroughfare
            
            DispatchQueue.main.async {
                
                if streetName != nil && buildNumber != nil {
                    self.addressLabel.text = "\(streetName!), \(buildNumber!)"
                } else if streetName != nil {
                    self.addressLabel.text = "\(streetName!)"
                } else {
                    self.addressLabel.text = ""
                }
            }
        }
    }
    
    // показали наложение маршрутов на карте
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        
        return renderer
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        mapManager.checkLocationAuthorization(mapView: mapView,
                                              segueIdentifier: incomeSegueIdentifier)
    }
}
