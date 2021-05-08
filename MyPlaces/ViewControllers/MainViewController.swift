//
//  TableViewController.swift
//  MyPlaces
//
//  Created by Nikita on 27.04.21.
//

import UIKit
import RealmSwift

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let searchController = UISearchController(searchResultsController: nil)
    private var places: Results<Place>!
    private var filteredPlaces: Results<Place>! // для поиска
    private var ascendingSorting = true // по умолчанию сортировка по возрастанию
    private var searchBarIsEmpty: Bool { // является строка поиска пустой или нет
        
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var resersedSortingButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        places = realm.objects(Place.self)
        
        // настройка Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false // позволяем действовать с отображаемым контентом
        searchController.searchBar.placeholder = "Search yours Places"
        navigationItem.searchController = searchController // строка поиска интегрирована в Бар
        definesPresentationContext = true // отпускам строке поиска при переходе на другой экран.
    }

    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isFiltering == true {
            return filteredPlaces.count
        }
        return places.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomTableViewCell
        
//        var place = Place()
        
//        if isFiltering{
//            place = filteredPlaces[indexPath.row]
//        } else {
//            place = places[indexPath.row]
//        }
        
        let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]

        cell.nameLabel.text = place.name
        cell.locationLabel.text = place.location
        cell.typeLabel.text = place.type
        cell.imageOfPlace.image = UIImage(data: place.imageData!)
        cell.cosmosView.rating = place.rating

        return cell
    }
    
    // MARK: - Table view delegate
    
    // отменили выделение ячейки при тапе
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // менее избыточный  способ удаления!
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            let place = places[indexPath.row]
            StorageManage.deleteObject(place)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
     

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showDetail" {
            
            guard let indexPath = tableView.indexPathForSelectedRow else { return } // получаем индекс выбранной строки
            
            let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
            
            let newPlaceVC = segue.destination as! NewPlaceViewController
            newPlaceVC.currentPlace = place
        }
    }

    
    @IBAction func unwidSegue(_ segue: UIStoryboardSegue) {
        
        guard let newPlaceVC = segue.source as? NewPlaceViewController else { return }
        
        newPlaceVC.savePlace() // сохраняем введенные данные
        tableView.reloadData() // обновялем интерфейс
    }
    
    @IBAction func sortSelection(_ sender: UISegmentedControl) {
        
        sorting()
        tableView.reloadData()
    }
    
    
    @IBAction func reversedSorting(_ sender: Any) {
        
        ascendingSorting.toggle()
        sorting()
    }
    
    private func sorting() {
        
//        if segmentedControl.selectedSegmentIndex == 0 {
//            places = places.sorted(byKeyPath: "date", ascending: ascendingSorting)
//        } else {
//            places = places.sorted(byKeyPath: "name", ascending: ascendingSorting)
//        }
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            places = places.sorted(byKeyPath: "date", ascending: ascendingSorting)
        case 1:
            places = places.sorted(byKeyPath: "name", ascending: ascendingSorting)
        case 2:
            places = places.sorted(byKeyPath: "rating", ascending: ascendingSorting)
        default:
            break
        }
        
        tableView.reloadData()
    }
}


// MARK: - Searching

extension MainViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        
        filteredPlaces = places.filter("name CONTAINS[c] %@ OR location CONTAINS[c] %@", searchText, searchText)
        
        tableView.reloadData()
    }
}
