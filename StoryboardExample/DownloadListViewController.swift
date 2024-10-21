//
//  DownloadListViewController.swift
//  StoryboardExample
//
//  Created by Prithuvi on 21/10/24.
//

import UIKit
import Combine

class DownloadListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    var downloadManager: AppDownloadManager?
    var cancellables: Set<AnyCancellable> = []

    var downloads = ["Download 1", "Download 2", "Download 3"]

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeDownloadManager()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    func initializeDownloadManager() {
        downloadManager = AppDownloadManager()
        downloadManager?.$offlineAssets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] assets in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension DownloadListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadManager?.offlineAssets.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "downloadCell", for: indexPath) as? DownloadTableViewCell else {
            return UITableViewCell()
        }

        if let offlineAsset = downloadManager?.offlineAssets[indexPath.row] {
            cell.titleLabel.text = offlineAsset.title
            cell.infoLabel.text = "Download Status: \(offlineAsset.status)"
            
            let progress = (offlineAsset.percentageCompleted / 100)
            cell.progressView.progress = Float(progress)
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Handle cell selection if needed
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

import UIKit

class DownloadTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
}
