//
//  NewPlaceTableViewController.swift
//  MyPlaces
//
//  Created by Nikita on 28.04.21.
//

import UIKit
 
class NewPlaceViewController: UITableViewController {
    
    var currentPlace: Place!
    
    var imageIsChanged = false
    
    @IBOutlet weak var placeImage: UIImageView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var placeName: UITextField!
    @IBOutlet weak var placeLocation: UITextField!
    @IBOutlet weak var placeType: UITextField!
    @IBOutlet weak var ratingControl: RatingControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0,
                                                         y: 0,
                                                         width: tableView.frame.size.width,
                                                         height: 1)) // hide the footer row
        saveButton.isEnabled = false // кнопка save - инактивная
        placeName.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged) // проверка на заполнение поля NAME
        
        setupEditScreen() // вызов редактирования ячейки
    }
    
    // MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            
            let cameraIcon = #imageLiteral(resourceName: "camera")
            let photoIcon = #imageLiteral(resourceName: "photo")
            
            let actionSheet = UIAlertController(title: nil,
                                                message: nil,
                                                preferredStyle: .actionSheet)
            
            let camera = UIAlertAction(title: "Camera", style: .default) { _ in
                self.chooseImagePicker(source: .camera)
            }
            camera.setValue(cameraIcon, forKey: "image") // установили картинку напротив кнопки
            camera.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment") // установили название кнопки по левому краю
            
            let photo = UIAlertAction(title: "Photo", style: .default) { _ in
                self.chooseImagePicker(source: .photoLibrary)
            }
            photo .setValue(photoIcon, forKey: "image") // установили картинку напротив кнопки
            photo.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment") // установили название кнопки по левому краю
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            
            actionSheet.addAction(camera)
            actionSheet.addAction(photo)
            actionSheet.addAction(cancel)
            
            present(actionSheet, animated: true) // calling Alert
            
        } else {
            view.endEditing(true)
        }
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier != "showMap" {
            return
        }
        
        let mapVC = segue.destination as! MapViewController
        mapVC.place = currentPlace
    }
    
    // сохранения нового места
    func savePlace() {
        
        var image: UIImage?
        
        if imageIsChanged {
            image = placeImage.image
        } else {
            image = #imageLiteral(resourceName: "imagePlaceholder")
        }
        
        let imageData = image?.pngData()
        
        let newPlace = Place(name: placeName.text!,
                             location: placeLocation.text,
                             type: placeType.text,
                             imageData: imageData,
                             rating: Double(ratingControl.rating))
        
        if currentPlace != nil {
            // перезаписали сохраненные данные
            try! realm.write {
                
                currentPlace?.name = newPlace.name
                currentPlace?.location = newPlace.location
                currentPlace?.type = newPlace.type
                currentPlace?.imageData = newPlace.imageData
                currentPlace?.rating = newPlace.rating
            }
        } else {
            StorageManage.saveObject(newPlace) // сохраняем в базу.
        }
    }
    
    // окно редактирования
    private func setupEditScreen() {
        
        if currentPlace != nil {
            
            setupNavigationBar()
            imageIsChanged = true
            
            guard let data = currentPlace?.imageData, let image = UIImage(data: data) else { return } // конвертировали фото
            
            placeImage.image = image
            placeImage.contentMode = .scaleAspectFill // масштабировали изображение
            placeName.text = currentPlace?.name
            placeLocation.text = currentPlace?.location
            placeType.text = currentPlace?.type
            ratingControl.rating = Int(currentPlace.rating)
        }
    }
    // Navigation Bar для окна редактирования
    private func setupNavigationBar() {
        
        if let topItem = navigationController?.navigationBar.topItem {
            topItem.backBarButtonItem = UIBarButtonItem(title: "" , style: .plain, target: nil, action: nil) // сделали пустой кнопку возврата
        }
        navigationItem.leftBarButtonItem = nil // убрали кнопку Cancel
        title = currentPlace?.name // изменили заголовок на название ячейки
        saveButton.isEnabled = true // делам кнопку save - активной
        
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Text field delegate

extension NewPlaceViewController: UITextFieldDelegate {
    
    // hide the keyboard press DONE
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc private func textFieldChanged() {
        
        if placeName.text?.isEmpty == false {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
    
}

// MARK: Work with image

extension NewPlaceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func chooseImagePicker(source: UIImagePickerController.SourceType) {
        
        if UIImagePickerController.isSourceTypeAvailable(source) {
            
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self // делегат, а класс делегирует
            imagePicker.allowsEditing = true
            imagePicker.sourceType = source
            present(imagePicker, animated: true)
        }
    }
    // метод добавления фото
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        placeImage.image = info[.editedImage] as? UIImage // по ключу из InfoKey выбрали отредактированное фото
        placeImage.contentMode = .scaleAspectFill
        placeImage.clipsToBounds = true
        
        imageIsChanged = true
        
        dismiss(animated: true, completion: nil) // закрыли imagePickerController
    }
    
}
