//
//  UtilitiesTableViewHeaderView.swift
//  Hoarder
//
//  Created by Karol Moluszys on 04.05.2018.
//  Copyright © 2018 Karol Moluszys. All rights reserved.
//

import UIKit
import SnapKit

class UtilitiesTableViewHeaderView: UIView {
    let searchButton = UIButton()
    let addButton = UIButton()
    let searchBar = UISearchBar()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(searchButton)
        addSubview(addButton)
        addSubview(searchBar)

        searchButton.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.height.equalTo(44.0)
        }

        searchBar.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        addButton.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview()
            make.width.height.equalTo(44.0)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
