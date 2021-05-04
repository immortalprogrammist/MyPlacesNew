//
//  MapViewController.swift
//  MyPlaces
//
//  Created by Nikita on 02.05.21.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    var place = Place()
    let annotationIndetifier = "annotationIndetifier"
    let locationManager = CLLocationManager() // отвечает за настройку и управление службами геолокации
    let regionInMeters = 10_000.00 // должен быть double
    var incomeSegueIdentifier = ""
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapPinImage: UIImageView!
    @IBOutlet weak var adressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    
    
    override func viewDidLoad() {

        super.viewDidLoad()
        mapView.delegate = self

        setupMapView()
        checkLocationServices()
    }
    
    // MARK: IBActions
    
    // Перенапревление на местоположение пользователя
    @IBAction func centerViewInUserLocation() {
        
       showUserLocation()
    }
    
    // закрываем карту и выгружаем ее из памяти
    @IBAction func closeVC() {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func doneButtonPressed() {
        
        
    }
    
    //
    private func setupMapView() {
        
        if incomeSegueIdentifier == "showPlace" {
            setupPlacemark()
            mapPinImage.isHidden = true // крываем маркер, если переходим по сегвею showPlace
            adressLabel.isHidden = true
            doneButton.isHidden = true
        }
    }
    
    // маркер на карте
    private func setupPlacemark() {
        
        guard let location = place.location else { return } // извлекаем адрес
        
        let geocoder = CLGeocoder() // отвечает за преобразование географических координат и названий. конвертирует адрес в координаты
        geocoder.geocodeAddressString(location) { (placemarks, error) in // определяем местоположение на карте в виде строки
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return } // извлекаем опционал
            
            let placemark = placemarks.first // получили метку на карте
            
            // описываем точку на карте
            let annotation = MKPointAnnotation()
            annotation.title = self.place.name
            annotation.subtitle = self.place.type
            
            guard let placemarkLocation = placemark?.location else { return } // определяем местоположение маркера. присваиваем геопозицию placemark
            
            annotation.coordinate = placemarkLocation.coordinate // привязывает аннотацию к точке на карте
            
            // отображаем все аннотации
            self.mapView.showAnnotations([annotation], animated: true)
            self.mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    // метод для проверки включенных служб
    private func checkLocationServices() {
        
        // если доступны службы доставки, иначе вызываем алерт с инструкцией, как включить службы
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // отложил вызов алерта на одну секунду
                
                self.showAlert(
                    title: "Location Services are Disable",
                    message: "To enable it go: Settings -> Privacy -> Location Services and turn ON.")
            }
        }
    }
    
    private func setupLocationManager() {
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // точное местоположение пользователя
    }
    
    // проверка статуса на использование геопозиции
    private func checkLocationAuthorization() {
        
        let manager = CLLocationManager()
    
        switch manager.authorizationStatus { // всего пять статусов
        case .authorizedWhenInUse: // разрешено определять геолокацию в момент использования приложения
            mapView.showsUserLocation = true
            if incomeSegueIdentifier == "getAdress" { showUserLocation() }
            break
        case .denied: // отказано использовать службу геолокации
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // отложил вызов алерта на одну секунду
                
                self.showAlert(
                    title: "Location Services are Disable",
                    message: "To enable it go: Settings -> Privacy -> Location Services and turn ON.")
            }
            break
        case .notDetermined: // статус неопределен
            locationManager.requestWhenInUseAuthorization() // запрос на использование геолокации в момент использования приложения
            break
        case .restricted: // приложение не авторизовано для служб геолокации
            break
        case .authorizedAlways: // разрешено постоянно использовать службу геолокации
            break
        @unknown default:
            print("New case is available")
        }
    }
    
    private func showUserLocation() {
        
        if let location = locationManager.location?.coordinate { // проверяем координаты пользователя
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters) // определяем регион
            
            mapView.setRegion(region, animated: true) // устанавливаем регион отображения на экране
        }
    }
    
    private func showAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else { return nil } // убеждаемся, что аннотация не является текущим местоположением пользователя и не создаем аннотации для точки.
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIndetifier) as? MKPinAnnotationView // объект класса MKAnnotationView, а MKPinAnnotationView скастили для того, чтобы была видна булавочка на карте
        
        // Если на карте не окажется ни одного представления аннотации, которое мы могли переиспользовать, инициализируем объект новым значением
        if annotationView == nil {
            
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIndetifier) // инициализация
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
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}
