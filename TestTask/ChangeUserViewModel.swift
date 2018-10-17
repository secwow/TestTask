//
//  changeUserViewModel.swift
//  TestTask
//
//  Created by Dmytro on 10/17/18.
//  Copyright © 2018 LampIdeaSoftware. All rights reserved.
//

import UIKit

enum ResponseType {
    case successfull, failed
}

struct Response {
    let type: ResponseType
    let info: String
}

struct ChangeUserViewModelObserver {
    var actionDone: ((Response?)->())
}

class ChangeUserViewModel {
    let model = UserModel()
    let observer: ChangeUserViewModelObserver

    init (observer: ChangeUserViewModelObserver) {
        self.observer = observer
    }

    func validateInput(firstName: String?, lastName: String?, email: String?, imageURL: String?) -> [String] {
        var errorArray = [String]()

        guard let firstName = firstName, let lastName = lastName, let email = email, let imageURL = imageURL else {
            errorArray.append("Please fill all fields")
            return errorArray
        }

        if firstName.isEmpty || lastName.isEmpty || email.isEmpty || imageURL.isEmpty {
            errorArray.append("Please fill all fields")
        }

        let pattern = "\\S+@\\S+\\.\\S+"

        if (email.range(of: pattern, options: .regularExpression) == nil) {
            errorArray.append("Wrong email format")
        }

        return errorArray
    }

    func updateUser(user: User) {
        self.model.updateUser(user: user, completition: observer.actionDone)
    }

    func createUser(user: User) {
        self.model.createUser(user: user, completition: observer.actionDone)
    }
}
