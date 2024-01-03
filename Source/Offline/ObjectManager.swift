//
//  RelamObjectManager.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 03/01/24.
//

import Foundation
import RealmSwift
import Realm

public class ObjectManager<T: Object> {
    let realm = try! Realm()
    
    func create(_ attributes: [String: Any]) throws -> T {
        let object = T()
        try self.raiseErrorIfInvalidAttributePassed(object, attributes)
        
        for (key, value) in attributes {
            object[key] = value
        }
        
        try realm.write {
            realm.add(object)
        }
        
        return object
    }
    
    func filter(predicate: NSPredicate) -> Results<T> {
        print("hihihi",(realm.objects(T.self).filter(predicate).count))
        return realm.objects(T.self).filter(predicate)
    }
    
    private func raiseErrorIfInvalidAttributePassed(_ object: T, _ attributes: [String: Any]) throws {
        for (key, _) in attributes {
            if object[key] == nil {
                throw ModelError.invalidAttribute(attributeName: key)
            }
        }
    }
    
}


enum ModelError: Error {
    case multipleObjectsReturned
    case objectDoesNotExist
    case duplicatePrimaryKeyValue
    case invalidAttribute(attributeName: String)
}
