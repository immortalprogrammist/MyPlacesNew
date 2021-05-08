//
//  MapManager.swift
//  MyPlaces
//
//  Created by Nikita on 07.05.21.
//

import UIKit
import MapKit

class MapManager {
    
    let locationManager = CLLocationManager() // отвечает за настройку и управление службами геолокации
    
    private var placeCoordinate: CLLocationCoordinate2D?
    private let regionInMeters = 1000.00 // должен быть double
    private var directionsArray: [MKDirections] = []
    
    // маркер заведений на карте
    func setupPlacemark(place: Place, mapView: MKMapView) {
        
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
            annotation.title = place.name
            annotation.subtitle = place.type
            
            guard let placemarkLocation = placemark?.location else { return } // определяем местоположение маркера. присваиваем геопозицию placemark
            
            annotation.coordinate = placemarkLocation.coordinate // привязывает аннотацию к точке на карте
            self.placeCoordinate = placemarkLocation.coordinate // получаем координаты заведения для прокладки маршрута
            
            // отображаем все аннотации
            mapView.showAnnotations([annotation], animated: true)
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    // Проверка доступности сервисов геолокации
    func checkLocationServices(mapView: MKMapView, segueIdentifier: String, clouser: () -> ()) {
        
        // если доступны службы доставки, иначе вызываем алерт с инструкцией, как включить службы
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkLocationAuthorization(mapView: mapView, segueIdentifier: segueIdentifier)
            clouser()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // отложил вызов алерта на одну секунду
                
                self.showAlert(
                    title: "Location Services are Disable",
                    message: "To enable it go: Settings -> Privacy -> Location Services and turn ON.")
            }
        }
    }
    
    // Проверка авторизации приложения для использования сервисов геолокации
    func checkLocationAuthorization(mapView: MKMapView, segueIdentifier: String) {
        
        let manager = CLLocationManager()
    
        switch manager.authorizationStatus { // всего пять статусов
        case .authorizedWhenInUse: // разрешено определять геолокацию в момент использования приложения
            mapView.showsUserLocation = true
            if segueIdentifier == "getAddress" { showUserLocation(mapView: mapView) }
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
    
    // Фокус карты на местоположении пользователя
    func showUserLocation(mapView: MKMapView) {
        
        if let location = locationManager.location?.coordinate { // проверяем координаты пользователя
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters) // определяем регион
            
            mapView.setRegion(region, animated: true) // устанавливаем регион отображения на экране
        }
    }
    
    // Строим маршрут от местоположения пользователя до заведения
    func getDirections(for mapView: MKMapView, previousLocation: (CLLocation) -> ()) {
        
        // определяем координаты местомоложения пользователя
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Error", message: "Current location is not found")
            return
        }
        
        // режим постоянного отслеживания текущего местоположения пользователя
        locationManager.startUpdatingLocation()
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
        
        // выполнение запроса на прокладку маршрута
        guard let request = createDirectionsRequest(from: location) else {
            showAlert(title: "Error", message: "Destination is not found")
            return
        }
    
        let direction = MKDirections(request: request) // создаем маршрут на основе сведеней, которые имеются в запросе
        resetMapView(withNew: direction, mapView: mapView)
        
        direction.calculate { (response, error) in // запуск расчета маршрута
            
            if let error = error {
                print(error)
                return
            }
            
            guard let response = response else { // извлекаем обработаный маршртур
                self.showAlert(title: "Error", message: "Direction is not available")
                return
            }
            // объект response содержит в себе массив routes с маршрутами. Переберем их:
            for route in response.routes {
                mapView.addOverlay(route.polyline) //
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true) // фокусируем карту от точки А до Б
                
                let distance = String(format: "%.1f", route.distance / 1000) // определяем растояние в км.
                let timeInterval = String(format: "%.1f", route.expectedTravelTime / 60) // время в пути
                
                print("Distance: \(distance), time: \(timeInterval)")
            }
        }
    }
    
    // Настройка запроса для расчета маршрута
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        
        guard let destinationCoordinate = placeCoordinate else { return nil }// координаты места назначение
        let startingLocation = MKPlacemark(coordinate: coordinate) // координаты начала маршрута
        let destination = MKPlacemark(coordinate: destinationCoordinate) // координаты пункта назначения
        
        // запрос на построение маршрута от точки А до точки Б
        let request  = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation) // стартовая точка
        request.destination = MKMapItem(placemark: destination) // конечная точка
        request.transportType = .automobile // тип транспорта
//        request.requestsAlternateRoutes = true // разрашение на постройку альтернативных маршрутов
        
        return request
    }
    
    // Меняем отображаемую зону области карты в соответствии с перемещением пользователя
    func startTrackingUserLocation(for mapView: MKMapView, and location: CLLocation?, clouser: (_ currentLocation:
        CLLocation) -> ()) {
        
        guard let location = location else { return }
        let center = getCenterLocation(for: mapView)
        guard center.distance(from: location) > 50 else { return }   // определяем расстояние до центра текущей области от предыдущей точки. если дистанция более 50м
        
        clouser(center)
    }
    
    // Сброс всех ранее простроенных маршрутов перед построением нового
    func resetMapView(withNew directions: MKDirections, mapView: MKMapView) {
    
        mapView.removeOverlays(mapView.overlays) // удаляем наложение текущего маршрута
        directionsArray.append(directions) // добавляем в массив текущение маршруты
        let _ = directionsArray.map { $0.cancel() } // отменяем действующие маршруты
        directionsArray.removeAll() // удаляем их с карты
    }
    
    // Определение центра отображаемой области карты
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        
        // Сначала узнаем широту и долготу
        let latitude = mapView.centerCoordinate.latitude // широта
        let longitude = mapView.centerCoordinate.longitude // долгота
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    private func showAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(okAction)
        
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
