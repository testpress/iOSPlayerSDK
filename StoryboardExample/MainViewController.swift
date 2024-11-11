//
//  MainViewController.swift
//  StoryboardExample
//
//  Created by Prithuvi on 21/10/24.
//

import Foundation
import UIKit

class MainViewController: UIViewController {
    
    @IBOutlet weak var sample1: UIButton!
    @IBOutlet weak var sample2: UIButton!
    @IBOutlet weak var sample3: UIButton!
    @IBOutlet weak var downloads: UIButton!
    
    @IBAction func sample1Tapped(_ sender: UIButton) {
        // https://app.tpstreams.com/embed/g2udjm/7T8MstHRh8u/?access_token=7367f42f-42a8-4058-96e7-844efc8bb596
        presentPlayerViewController(assistId: "7T8MstHRh8u", accessToken: "7367f42f-42a8-4058-96e7-844efc8bb596")
    }
    
    @IBAction func sample2Tapped(_ sender: UIButton) {
        presentPlayerViewController(assistId: "72c9RRHj3M8", accessToken: "47c686d7-a50b-41f9-b2cd-0660960c357f")
    }
    
    @IBAction func sample3Tapped(_ sender: UIButton) {
        presentPlayerViewController(assistId: "9JRmKJXZSMe", accessToken: "1ae5e10e-fc85-4aa9-9a0a-6c195e9b0034")
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
