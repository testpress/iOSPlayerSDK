//
//  ObjectManager.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 09/01/24.
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
    
    func update(object: T, with attributes: [String: Any]) {
        try! realm.write {
            for (key, value) in attributes {
                object[key] = value
            }
        }
    }
}
