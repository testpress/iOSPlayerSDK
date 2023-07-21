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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupPlayerView()
        player?.play()
    }
    
    func setupPlayerView(){
        player = TPAVPlayer(assetID: "8eaHZjXt6km", accessToken: "16b608ba-9979-45a0-94fb-b27c1a86b3c1")
        let playerView = TPStreamUIKitPlayerView(frame: playerContainer.bounds, player: player!)
        playerContainer.addSubview(playerView)
    }
}

