//
//  TPStreamPlayer.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 31/05/23.
//

import SwiftUI

public struct TPStreamPlayerView: View {
    @State private var isFullScreen = false
    
    var player: TPAVPlayer
    
    public init(player: TPAVPlayer) {
        self.player = player
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                AVPlayerBridge(player: player)
                PlayerControlsView(player: player, isFullscreen: $isFullScreen)
            }
            .onChange(of: isFullScreen, perform: changeOrientation)
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                isFullScreen = UIDevice.current.orientation.isLandscape
            }
            .padding(isFullScreen ? EdgeInsets(top: 0, leading: 48, bottom: 32, trailing: 48) : EdgeInsets())
            .frame(width: isFullScreen ? UIScreen.main.fixedCoordinateSpace.bounds.height : geometry.size.width,
                   height: isFullScreen ? UIScreen.main.fixedCoordinateSpace.bounds.width : geometry.size.height)
            .background(Color.black)
            .edgesIgnoringSafeArea(isFullScreen ? .all : [])
            .statusBarHidden(isFullScreen)
        }
    }
 
    func changeOrientation(isFullscreen: Bool){
        let orientation: UIInterfaceOrientation = isFullscreen ? .landscapeRight : .portrait
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
    }
}
