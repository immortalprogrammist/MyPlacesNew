//
//  MapViewController.swift
//  MyPlaces
//
//  Created by Nikita on 02.05.21.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    // закрываем карту и выгружаем ее из памяти
    @IBAction func closeVC() {
        dismiss(animated: true, completion: nil)
    }

}
