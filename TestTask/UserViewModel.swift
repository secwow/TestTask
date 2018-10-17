//
//  UserViewModel.swift
//  TestTask
//
//  Created by Dmytro on 10/16/18.
//  Copyright © 2018 LampIdeaSoftware. All rights reserved.
//

import Foundation

enum UserRecordState {
    case new, downloaded, failed
}

class UserRecord {
    let user: User
    var state: UserRecordState = .new
    var data: Data?

    init (user: User) {
        self.user = user
    }
}

struct UserViewModelObserver {
    let userUpdated: ((Int, UserRecord)->())
    let allUsersUpdated: (()->())
}

class UserViewModel {
    var users: [UserRecord]
    let userEvents: UserViewModelObserver
    var userModel: UserModel = UserModel()
    var imageDownloader: UserDataDownloader


    init(observer: UserViewModelObserver) {
        self.userEvents = observer
        self.users = []
        self.imageDownloader = UserDataDownloader(recordUpdated: observer.userUpdated)
    }

    func fetchUsers() {
        self.userModel.fetchUsers {[weak self] (users) in
            for user in users {
                self?.users.append(UserRecord(user: user))
            }

            self?.userEvents.allUsersUpdated()
        }
    }

    func downloadImage(to index: Int) {
        let userRecord = self.users[index]
        switch userRecord.state {
        case .new:
            print("Download new image")
            self.imageDownloader.performUserDownloadingTask(records: [index: self.users[index]])
        case .downloaded:
             print("Image already downloaded")
        case .failed:
            print("Image downloading failed")
        }
    }

    func downloadImages(for indexies: [Int]) {
        var records = [Int: UserRecord]()

        for index in indexies {
            records[index] = self.users[index]
        }

        self.imageDownloader.deleteAllItemsFromQueue()
        self.imageDownloader.performUserDownloadingTask(records: records)
    }

    func resumeAllDataDowloading() {
        self.imageDownloader.resumePictureDownloading()
    }

    func suspendAllDataDowloading() {
         self.imageDownloader.suspendPictureDownloadling()
    }
}
