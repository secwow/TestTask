//
//  ChangeUserViewController.swift
//  TestTask
//
//  Created by Dmytro on 10/16/18.
//  Copyright © 2018 LampIdeaSoftware. All rights reserved.
//

import UIKit

enum ViewMode {
    case create, edit
}

class ChangeUserViewController: UIViewController {
    @IBOutlet weak var emailLabel: UITextField!
    @IBOutlet weak var firstNameLabel: UITextField!
    @IBOutlet weak var lastNameLabel: UITextField!
    @IBOutlet weak var imageURLLabel: UITextField!

    var viewModel: ChangeUserViewModel!
    var mode: ViewMode = .create
    var user: User!

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.mode == .edit {
            self.emailLabel.text = self.user.email
            self.firstNameLabel.text = self.user.name
            self.lastNameLabel.text = self.user.lastName
            self.imageURLLabel.text = self.user.avatar
        }

        let responseHandler = {[weak self] (response: Response?) in
            DispatchQueue.main.async {
                if let response = response {
                    switch response.type {
                    case .successfull:
                        self?.presentPopup(with: "Successfully", message: response.info)
                    case .failed:
                        self?.presentPopup(with: "Failed", message: response.info)
                    }
                    return
                }
                self?.dismiss(animated: true)
            }
        }
        let observer = ChangeUserViewModelObserver(actionDone: responseHandler)
        self.viewModel = ChangeUserViewModel(observer: observer)
    }

    func presentPopup(with title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }

    @IBAction func sendData(_ sender: Any) {
        let errorArray = self.viewModel.validateInput(firstName: firstNameLabel.text, lastName: lastNameLabel.text, email: emailLabel.text, imageURL: imageURLLabel.text)

        if !errorArray.isEmpty {
            self.presentPopup(with: "Validation error", message: errorArray.reduce("", { $0 + $1}))
        } else {

            switch self.mode {
            case .create:
                let user = User(id: 0, name: firstNameLabel.text!,
                                lastName: lastNameLabel.text!,
                                email: emailLabel.text!,
                                avatar: imageURLLabel.text!)
                self.viewModel.createUser(user: user)
            case .edit:
                let user = User(id: self.user.id,
                                name: firstNameLabel.text!,
                                lastName: lastNameLabel.text!,
                                email: emailLabel.text!,
                                avatar: imageURLLabel.text!)
                self.viewModel.updateUser(user: user)
            }
        }
    }
}
