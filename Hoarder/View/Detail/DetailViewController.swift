//
//  DetailViewController.swift
//  Hoarder
//
//  Created by Karol Moluszys on 06.05.2018.
//  Copyright © 2018 Karol Moluszys. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var titlePLTextField: UITextField!
    @IBOutlet weak var titleORGTextField: UITextField!

    var movie: Movie?
    var service: RealmService?
    let tapGesture = UITapGestureRecognizer()

    override func viewDidLoad() {
        super.viewDidLoad()

        codeTextField.text = movie?.code
        titlePLTextField.text = movie?.titlePL
        titleORGTextField.text = movie?.titleORG

        tapGesture.addTarget(self, action: #selector(resignKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    @objc func resignKeyboard() {
        codeTextField.resignFirstResponder()
        titlePLTextField.resignFirstResponder()
        titleORGTextField.resignFirstResponder()
    }

    @IBAction func saveAction(sender: UIButton) {
        guard let movie = movie else {
            return
        }

        service?.update(movie: movie,
                        code: codeTextField.text ?? "",
                        titlePL: titlePLTextField.text ?? "",
                        titleORG: titleORGTextField.text ?? "")

        navigationController?.popViewController(animated: true)
    }
}
