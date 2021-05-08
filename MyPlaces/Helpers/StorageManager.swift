//
//  StorageManager.swift
//  MyPlaces
//
//  Created by Nikita on 29.04.21.
//

import RealmSwift

let realm = try! Realm()

class StorageManage {
    
    static func saveObject(_ place: Place) {
        
        try! realm.write {
            realm.add(place)
        }
    }
    
    static func deleteObject(_ place: Place) {
        
        try! realm.write {
            realm.delete(place)
        }
    }
}
