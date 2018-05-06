//
//  RealmService.swift
//  Hoarder
//
//  Created by Karol Moluszys on 02.05.2018.
//  Copyright © 2018 Karol Moluszys. All rights reserved.
//

import UIKit
import RealmSwift

class RealmService: NSObject {
    private let realm: Realm
    private let movies: Results<Movie>

    override init() {
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                switch oldSchemaVersion {
                case 1:
                    break
                default:
                    RealmService.zeroToOne(migration: migration)
                }
        })

        realm = try! Realm(configuration: config)
        movies = realm.objects(Movie.self)
    }

    func store(code: String) {
        let movie = Movie()
        movie.code = code

        try! realm.write {
            realm.add(movie)
        }
    }

    func store(titlePL: String) {
        let movie = Movie()
        movie.titlePL = titlePL

        try! realm.write {
            realm.add(movie)
        }
    }

    func store(titleORG: String) {
        let movie = Movie()
        movie.titleORG = titleORG

        try! realm.write {
            realm.add(movie)
        }
    }

    func getAll() -> Results<Movie> {
        return movies
    }

    func search(code: String) -> Bool {
        return movies.filter(NSPredicate(format: "code == %@", code)).first != nil
    }

    func search(code: String) -> Results<Movie> {
        return movies.filter(NSPredicate(format: "(code CONTAINS[cd] %@) OR (titlePL CONTAINS[cd] %@) OR (titleORG CONTAINS[cd] %@)", code, code, code))
    }

    func update(movie: Movie, code: String, titlePL: String, titleORG: String) {
        try! realm.write {
            movie.code = code
            movie.titlePL = titlePL
            movie.titleORG = titleORG
        }
    }

    func delete(movie: Movie) {
        try! realm.write {
            realm.delete(movie)
        }
    }
}

private extension RealmService {
    static func zeroToOne(migration: Migration) {
        migration.enumerateObjects(ofType: Movie.className()) { oldObject, newObject in
            newObject!["titlePL"] = ""
            newObject!["titleORG"] = ""
        }
    }
}
