//
//  ViewController.swift
//  StoryboardExample
//
//  Created by Testpress on 20/07/23.
//

import UIKit
import TPStreamsSDK
import AVKit

class ViewController: UIViewController {
    @IBOutlet weak var playerContainer: UIView!
    
    var player: TPAVPlayer?
    var playerViewController: TPStreamPlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupPlayerView()
        player?.play()
    }
    
    func setupPlayerView(){
        player = TPAVPlayer(assetID: "8eaHZjXt6km", accessToken: "16b608ba-9979-45a0-94fb-b27c1a86b3c1")
        playerViewController = TPStreamPlayerViewController()
        playerViewController?.player = player
        playerViewController?.delegate = self

        addChild(playerViewController!)
        playerContainer.addSubview(playerViewController!.view)
        playerViewController!.view.frame = playerContainer.bounds
    }
}

extension ViewController: TPPlayerViewControllerDelegate {
    func willEnterFullScreenMode() {
        print("willEnterFullScreenMode")
    }
    
    func didEnterFullScreenMode() {
        print("didEnterFullScreenMode")
    }
    
    func willExitFullScreenMode() {
        print("willExitFullScreenMode")
    }
    
    func didExitFullScreenMode() {
        print("didExitFullScreenMode")
    }
}

