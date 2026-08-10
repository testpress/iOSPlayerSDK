//
//  ViewController.swift
//  StoryboardExample
//
//  Created by Testpress on 20/07/23.
//

import UIKit
import TPStreamsSDK
import AVKit

class PlayerViewController: UIViewController {
    @IBOutlet weak var playerContainer: UIView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    var assistId: String?
    var accessToken: String?
    
    var player: TPAVPlayer?
    var playerViewController: TPStreamPlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupPlayerView()
        player?.play()
    }
    
    func setupPlayerView(){
        if (TPStreamsDownloadManager.shared.isAssetDownloaded(assetID: assistId!)){
            player = TPAVPlayer(offlineAssetId: assistId!) { error in
                guard error == nil else {
                    print("Setup error: \(error!.localizedDescription)")
                    return
                }
            }
            player?.onRequestOfflineLicenseRenewal = { [weak self] assetId, completion in
                debugPrint("onRequestOfflineLicenseRenewal")
                let token = self?.accessToken ?? "9327e2d0-fa13-4288-902d-840f32cd0eed"
                completion(token, 40)
            }
            player?.onError = { error, _ in
                print("Player error: \(error.localizedDescription)")
            }
        } else {
            player = TPAVPlayer(assetID: assistId!, accessToken: accessToken!){ error in
                guard error == nil else {
                    print("Setup error: \(error!.localizedDescription)")
                    return
                }

                print("TPAVPlayer setup successfully")
                print("Available qualities: \(self.player?.availableVideoQualities ?? [])")
                let qualities = self.player?.availableVideoQualities ?? []
                for quality in qualities {
                    if quality.resolution == "240p" {
                        self.player?.changeVideoQuality(to: quality)
                    }
                }
            }
        }
        playerViewController = TPStreamPlayerViewController()
        playerViewController?.player = player
        playerViewController?.delegate = self

        
        let config = TPStreamPlayerConfigurationBuilder()
            .setPreferredForwardDuration(15)
            .setPreferredRewindDuration(5)
            .setprogressBarThumbColor(.systemBlue)
            .setwatchedProgressTrackColor(.systemBlue)
            .showDownloadOption()
            .enableCaptions(true)
            .autoSelectFirstSubtitle(true)
            .setUserId("storyboard-example-user")
            .setWatermarks([
                WatermarkConfig(
                    text: "storyboard-example-user",
                    x: 0,
                    y: 50,
                    color: 0xFFFFFFFF,
                    textSize: 14,
                    opacity: 0.3
                ),
                WatermarkConfig(
                    text: "storyboard-example-user",
                    x: 150,
                    y: 150,
                    color: 0xFFFF0000,
                    textSize: 20,
                    opacity: 0.5,
                    animation: WatermarkAnimation(type: .pingPong, duration: 10000)
                )
            ])
            .build()
        
        playerViewController?.config = config

        addChild(playerViewController!)
        playerContainer.addSubview(playerViewController!.view)
        playerViewController!.view.frame = playerContainer.bounds
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        player?.pause()
        dismiss(animated: true, completion: nil)
    }
}

extension PlayerViewController: TPStreamPlayerViewControllerDelegate {
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
    
    func didTapReplay() {
        print("didTapReplay")
    }
}

