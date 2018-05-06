//
//  Movie.swift
//  Hoarder
//
//  Created by Karol Moluszys on 02.05.2018.
//  Copyright © 2018 Karol Moluszys. All rights reserved.
//

import RealmSwift

class Movie: Object {
    @objc dynamic var code: String = ""
    @objc dynamic var titlePL: String = ""
    @objc dynamic var titleORG: String = ""
}
