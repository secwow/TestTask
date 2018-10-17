//
//  ViewController.swift
//  TestTask
//
//  Created by Dmytro on 10/16/18.
//  Copyright © 2018 LampIdeaSoftware. All rights reserved.
//

import UIKit

class UserViewController: UIViewController {
    struct Constants {
        static let storyboardID = "Main"
        static let viewControllerID = "EditUserStoryboard"
        static let cellID = "cell"
    }

    @IBOutlet weak var usersTable: UITableView!
    var viewModel: UserViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.usersTable.delegate = self
        self.usersTable.dataSource = self

        let userUpdated = {[weak self](index: Int, record: UserRecord) -> () in
            DispatchQueue.main.async {
                self?.usersTable.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            }
        }

        let usersUpdated = {[weak self] ()->() in
            DispatchQueue.main.async {
                self?.usersTable.reloadData()
            }
        }
        let observer = UserViewModelObserver(userUpdated:userUpdated, allUsersUpdated:usersUpdated)
        self.viewModel = UserViewModel(observer: observer)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.viewModel.fetchUsers()
    }

    func getAllImagesForVisibleCells() {
        if let visibleCellIndexies = self.usersTable.indexPathsForVisibleRows {
            let setOfVisibleCells = Set<Int>(visibleCellIndexies.map({$0.row}))
            var notDowloaded = Set<Int>()
            for i in 0..<self.viewModel.users.count {
                let userRecord = self.viewModel.users[i]
                if userRecord.state != .downloaded {
                    notDowloaded.insert(i)
                }
            }
            let result = setOfVisibleCells.intersection(notDowloaded)
            self.viewModel.downloadImages(for: Array(result))
        }
    }
}

extension UserViewController: UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.users.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let controller = UIStoryboard(name: Constants.storyboardID, bundle: nil).instantiateViewController(withIdentifier: Constants.viewControllerID) as? ChangeUserViewController {
            controller.mode = .edit
            controller.user = self.viewModel.users[indexPath.row].user
            self.present(controller, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = self.usersTable.dequeueReusableCell(withIdentifier: Constants.cellID, for: indexPath) as? CellViewController {
            let userRecord = self.viewModel.users[indexPath.row]

            cell.emailLabel.text = userRecord.user.email
            cell.nameLabel.text = userRecord.user.name
            cell.lastNameLabel.text = userRecord.user.lastName
            switch (userRecord.state) {
            case .new:
                if !self.usersTable.isDragging && !self.usersTable.isDecelerating {
                     self.viewModel.downloadImage(to: indexPath.row)
                }
            case .downloaded:
                if let imageDate = userRecord.data  {
                    cell.avatarImageView?.image = UIImage(data: imageDate)
                }
            case .failed:
                print("failed")
            }
            return cell
        }

        return UITableViewCell()
    }

   func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.viewModel.suspendAllDataDowloading()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
             self.getAllImagesForVisibleCells()
             self.viewModel.resumeAllDataDowloading()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.viewModel.resumeAllDataDowloading()
    }
}
