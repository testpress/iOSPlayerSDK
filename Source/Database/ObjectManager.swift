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

    func get(assetId: Any) -> T? {
        return realm.object(ofType: T.self, forPrimaryKey: assetId)
    }
}
