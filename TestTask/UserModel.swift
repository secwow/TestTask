//
//  Model.swift
//  TestTask
//
//  Created by Dmytro on 10/16/18.
//  Copyright © 2018 LampIdeaSoftware. All rights reserved.
//

import Foundation

class UserModel {
    struct Constants {
        static let BASE_URL = "https://cua-users.herokuapp.com"
    }

    struct UserSchema {
        static let firstName = "first_name"
        static let lastName = "last_name"
        static let id = "id"
        static let imageURL = "image_url"
        static let email = "email"
    }

    func fetchUsers(completition:@escaping (([User])->())) {
        guard let requestURL = URL(string:"\(Constants.BASE_URL)/users.php") else {
            return
        }

        URLSession.shared.dataTask(with: requestURL) {(responseData, response, error) in

            if let error = error {
                print(error)
            }

            guard let data = responseData, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]], let usersJson = json else {
                return
            }

            var users = [User]()

            for user in usersJson {

                guard let id = user[UserSchema.id] as? String,
                    let name = user[UserSchema.firstName] as? String,
                    let lastName = user[UserSchema.lastName] as? String,
                    let email = user[UserSchema.email] as? String,
                    let imageURL = user[UserSchema.imageURL] as? String else {
                    continue
                }

                guard let userID = Int(id) else {
                    continue
                }

                users.append(User(id: userID, name: name, lastName: lastName, email: email, avatar: imageURL))
            }
            
            completition(users)

        }.resume()
    }

    func createUser(user: User, completition: ((Response?)->())?) {
        guard let requestURL = URL(string:"\(Constants.BASE_URL)/users.php") else {
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"

        let userDictionary = ["user": [UserSchema.firstName: user.name, UserSchema.lastName: user.lastName, UserSchema.email: user.email, UserSchema.imageURL: user.avatar]]
        let requestData = try? JSONSerialization.data(withJSONObject: userDictionary, options: [])

        request.httpBody = requestData

        URLSession.shared.dataTask(with: request) { (responseDate, URLResponse, error) in
            guard let httpResponse = URLResponse as? HTTPURLResponse else {
                return
            }

            var response: Response?

            defer { if let completition = completition {completition(response) }}

            if httpResponse.statusCode == 201 {
                response = Response(type: .successfull, info: "User successfully sing in")
            }

            if httpResponse.statusCode == 422 {

                if let data = responseDate, let responseData = String(data: data, encoding: .utf8) {
                     response = Response(type: .failed, info: responseData)
                }
            }

            print("Response status: \(httpResponse.statusCode)")
        }.resume()
    }

    func updateUser(user: User, completition: ((Response?)->())?) {
        guard let requestURL = URL(string:"\(Constants.BASE_URL)/users.php?user_id=\(user.id)") else {
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"

        let userDictionary = ["user": [UserSchema.firstName: user.name, UserSchema.lastName: user.lastName, UserSchema.email: user.email, UserSchema.imageURL: user.avatar]]
        let requestData = try? JSONSerialization.data(withJSONObject: userDictionary, options: [])

        request.httpBody = requestData

        URLSession.shared.dataTask(with: request) { (responseDate, URLResponse, error) in
            guard let httpResponse = URLResponse as? HTTPURLResponse else {
                return
            }

            var response: Response?

            defer { if let completition = completition {completition(response) }}

            if httpResponse.statusCode == 200 {
                response = Response(type: .successfull, info: "User successfully updated")
            }

            if httpResponse.statusCode == 422 {

                if let data = responseDate, let responseData = String(data: data, encoding: .utf8) {
                    response = Response(type: .failed, info: responseData)
                }
            }

            print("Response status: \(httpResponse.statusCode)")
        }.resume()
    }
}

class UserDataDownloader {
    lazy var downloadQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "Download queue"
        return queue
    }()
    var pendingOperations: [Int: UserDataOperation] = [:]
    var recordUpdated: ((Int, UserRecord)->())

    init(recordUpdated: @escaping ((Int, UserRecord)->())) {
        self.recordUpdated = recordUpdated
    }

    func performUserDownloadingTask(records: [Int: UserRecord]) {

        for record in records {
            let operation = UserDataOperation(user: record.value) {[weak self] in
                if record.value.state == .downloaded {
                    self?.recordUpdated(record.key, record.value)
                }
                self?.pendingOperations.removeValue(forKey: record.key)
            }
            self.pendingOperations[record.key] = operation
            self.downloadQueue.addOperation(operation)
        }
    }

    func suspendPictureDownloadling() {
        self.downloadQueue.isSuspended = true
    }

    func resumePictureDownloading() {
        self.downloadQueue.isSuspended = false
    }

    func deleteAllItemsFromQueue() {

        self.downloadQueue.cancelAllOperations()
    }
}

class UserDataOperation: Operation {
    var userRecord: UserRecord
    var recordUpdated: (()->())

    init(user: UserRecord, recordUpdated: @escaping (()->())) {
        self.userRecord = user
        self.recordUpdated = recordUpdated
    }

    override func main() {
        defer {
            self.recordUpdated()
        }

        if isCancelled {
            return
        }

        guard let url = URL(string: userRecord.user.avatar), let data = try? Data(contentsOf: url) else {
            self.userRecord.state = .failed
            return
        }

        self.userRecord.data = data
        self.userRecord.state = .downloaded
        print("Successfully downloaded ")
    }
}

