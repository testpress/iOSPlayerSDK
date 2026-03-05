//
//  MainViewController.swift
//  StoryboardExample
//
//  Created by Prithuvi on 21/10/24.
//

import Foundation
import UIKit
import TPStreamsSDK

class MainViewController: UIViewController {
    
    @IBOutlet weak var sample1: UIButton!
    @IBOutlet weak var sample2: UIButton!
    @IBOutlet weak var sample3: UIButton!
    @IBOutlet weak var downloads: UIButton!
    @IBOutlet weak var downloadWithPicker: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func downloadTapped(_ sender: UIButton) {
        TPStreamsDownloadManager.shared.startDownload(
            assetID: "BEArYFdaFbt",
            accessToken: "ecf6366b-c2ee-408c-9472-6ed4e4b3047e",
            resolution: "140p",
            allowResolutionFallback: true,
            presentingViewController: self,
        ) { result in
            switch result {
            case .success(let offlineAsset):
                print("Download started: \(offlineAsset.title)")
            case .failure(let error):
                print("Download failed: \(error.message)")
            }
        }
    }
    
    @IBAction func sample1Tapped(_ sender: UIButton) {
        presentPlayerViewController(assistId: "42h2tZ5fmNf", accessToken: "9327e2d0-fa13-4288-902d-840f32cd0eed")
    }
    
    @IBAction func sample2Tapped(_ sender: UIButton) {
        presentPlayerViewController(assistId: "57gHcHDBxKX", accessToken: "5e28479d-69d8-41c7-9664-79b7eb8f1f95")
    }
    
    @IBAction func sample3Tapped(_ sender: UIButton) {
        presentPlayerViewController(assistId: "7BsJXTfb3hr", accessToken: "19c92b12-1a4e-4967-a34b-97724c092d26")
    }
    
    @IBAction func downloadsTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let downloadListVC = storyboard.instantiateViewController(withIdentifier: "DownloadListViewController") as? DownloadListViewController {
            downloadListVC.modalPresentationStyle = .fullScreen
            present(downloadListVC, animated: true, completion: nil)
        }
    }
    
    private func presentPlayerViewController(assistId: String, accessToken: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let playerVC = storyboard.instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController {
            playerVC.assistId = assistId
            playerVC.accessToken = accessToken
            playerVC.modalPresentationStyle = .fullScreen
            present(playerVC, animated: true, completion: nil)
        }
    }
}
