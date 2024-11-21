//
//  ObjectManager.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 04/10/24.
//

import Foundation
import RealmSwift

public class ObjectManager<T: Object> {
    let realm = try! Realm()
    
    func add(object: T) {
        try! realm.write {
            realm.add(object)
        }
    }
    
    func get(id: Any) -> T? {
        return realm.object(ofType: T.self, forPrimaryKey: id)
    }
    
    func get(where attributeKey: String, isEqualTo attributeValue: String) throws -> T? {
        let predicate = NSPredicate(format: "%K == %@", attributeKey, attributeValue)
        let matchingObjects = realm.objects(T.self).filter(predicate)
        
        guard let object = matchingObjects.first else {
            return nil
        }
        
        if matchingObjects.count > 1 {
            return nil
        }
        
        return object
    }
    
    func update(object: T, with attributes: [String: Any]) {
        try! realm.write {
            for (key, value) in attributes {
                object[key] = value
            }
        }
    }
    
    func update(id: Any, with attributes: [String: Any]) {
        guard let object = get(id: id) else {
            print("Object with id \(id) not found.")
            return
        }
        
        try! realm.write {
            for (key, value) in attributes {
                object[key] = value
            }
        }
    }
    
    func exists(id: Any) -> Bool {
        let object = realm.object(ofType: T.self, forPrimaryKey: id)
        return object != nil
    }
    
    func delete(id: Any) {
         try! realm.write {
             guard let deleteObject = get(id: id) else { return }
             realm.delete(deleteObject)
         }
     }
    
    func getAll() -> Results<T> {
        return realm.objects(T.self)
    }
}
