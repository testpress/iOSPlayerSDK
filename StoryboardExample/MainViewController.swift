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
        presentPlayerViewController(assistId: "95hBGFAhQYR", accessToken: "7d4e2ffb-3492-4cd4-8e5c-41b7af2f3e7f")
    }
    
    @IBAction func sample2Tapped(_ sender: UIButton) {
        presentPlayerViewController(assistId: "72c9RRHj3M8", accessToken: "47c686d7-a50b-41f9-b2cd-0660960c357f")
    }
    
    @IBAction func sample3Tapped(_ sender: UIButton) {
        presentPlayerViewController(assistId: "AgAFNEJn3kt", accessToken: "f9b11692-78c5-4d14-9385-5f1efb0b8f4e")
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
