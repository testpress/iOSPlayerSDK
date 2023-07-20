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
    
    var playerViewController: AVPlayerViewController?
    var player: AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupPlayer()
    }
    
    func setupPlayer(){
        player = TPAVPlayer(assetID: "8eaHZjXt6km", accessToken: "16b608ba-9979-45a0-94fb-b27c1a86b3c1")
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player

        addChild(playerViewController!)
        playerContainer.addSubview(playerViewController!.view)
        playerViewController!.view.frame = playerContainer.bounds
        player?.play()
    }
}

