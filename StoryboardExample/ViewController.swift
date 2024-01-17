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
        player = TPAVPlayer(assetID: "8r65J7EY6NP"){ error in
            guard error == nil else {
                print("Setup error: \(error!.localizedDescription)")
                return
            }

            print("TPAVPlayer setup successfully")
        }
        playerViewController = TPStreamPlayerViewController()
        playerViewController?.player = player
        playerViewController?.delegate = self

        
        let config = TPStreamPlayerConfigurationBuilder()
            .setPreferredForwardDuration(15)
            .setPreferredRewindDuration(5)
            .setprogressBarThumbColor(.systemBlue)
            .setwatchedProgressTrackColor(.systemBlue)
            .build()
        
        playerViewController?.config = config

        addChild(playerViewController!)
        playerContainer.addSubview(playerViewController!.view)
        playerViewController!.view.frame = playerContainer.bounds
    }
}

extension ViewController: TPStreamPlayerViewControllerDelegate {
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

