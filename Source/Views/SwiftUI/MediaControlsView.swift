//
//  MediaControlsView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 06/06/23.
//

import SwiftUI

@available(iOS 14.0, *)
struct MediaControlsView: View {
    @EnvironmentObject var player: TPStreamPlayerObservable
    private var playerViewConfig: TPStreamPlayerConfiguration
    
    init(playerViewConfig: TPStreamPlayerConfiguration){
        self.playerViewConfig = playerViewConfig
    }
    
    var body: some View {
        HStack() {
            Spacer()
            Button(action: { player.rewind(playerViewConfig.preferredRewindDuration) }) {
                Image("rewind", bundle: bundle)
                    .resizable()
                    .onAppear {
                        #if DEBUG
                        let img = UIImage(named: "rewind", in: bundle, compatibleWith: nil)
                        if let _ = img {
                            let path = bundle.path(forResource: "rewind", ofType: nil) ?? "\(bundle.bundlePath)/Assets.car/rewind"
                            print("[TPStreamsSDK] 🖼️ Loaded: 'rewind' (SwiftUI)")
                            print("[TPStreamsSDK] 📍 Path: \(path)")
                        } else {
                            print("[TPStreamsSDK] ❌ Failed: 'rewind' (SwiftUI)")
                            print("[TPStreamsSDK] 🔍 Searched In: \(bundle.bundlePath)")
                        }
                        #endif
                    }
                    .frame(width: 40, height: 40)
                    .brightness(-0.1)
            }
            Spacer()
            if player.observedStatus == "buffering" {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
            } else {
                Button(action: togglePlay) {
                    let imageName = player.observedStatus == "paused" ? "play" : "pause"
                    Image(imageName, bundle: bundle)
                        .resizable()
                        .onAppear {
                            #if DEBUG
                            let img = UIImage(named: imageName, in: bundle, compatibleWith: nil)
                            if let _ = img {
                                let path = bundle.path(forResource: imageName, ofType: nil) ?? "\(bundle.bundlePath)/Assets.car/\(imageName)"
                                print("[TPStreamsSDK] 🖼️ Loaded: '\(imageName)' (SwiftUI)")
                                print("[TPStreamsSDK] 📍 Path: \(path)")
                            } else {
                                print("[TPStreamsSDK] ❌ Failed: '\(imageName)' (SwiftUI)")
                                print("[TPStreamsSDK] 🔍 Searched In: \(bundle.bundlePath)")
                            }
                            #endif
                        }
                        .frame(width: 48, height: 48)
                        .brightness(-0.1)
                }
            }
            Spacer()
            Button(action: {player.forward(playerViewConfig.preferredForwardDuration)}) {
                Image("forward", bundle: bundle)
                    .resizable()
                    .onAppear {
                        #if DEBUG
                        let img = UIImage(named: "forward", in: bundle, compatibleWith: nil)
                        if let _ = img {
                            let path = bundle.path(forResource: "forward", ofType: nil) ?? "\(bundle.bundlePath)/Assets.car/forward"
                            print("[TPStreamsSDK] 🖼️ Loaded: 'forward' (SwiftUI)")
                            print("[TPStreamsSDK] 📍 Path: \(path)")
                        } else {
                            print("[TPStreamsSDK] ❌ Failed: 'forward' (SwiftUI)")
                            print("[TPStreamsSDK] 🔍 Searched In: \(bundle.bundlePath)")
                        }
                        #endif
                    }
                    .frame(width: 40, height: 40)
                    .brightness(-0.1)
            }
            Spacer()
        }
    }
    
    
    public func togglePlay(){
        if player.status == "paused" {
            player.play()
        } else {
            player.pause()
        }
    }
    
}
