//
//  TPStreamPlayer.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 31/05/23.
//

import SwiftUI

@available(iOS 14.0, *)
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
            .padding(.horizontal, isFullScreen ? 48 : 0)
            .frame(width: isFullScreen ? UIScreen.main.fixedCoordinateSpace.bounds.height : geometry.size.width,
                   height: isFullScreen ? UIScreen.main.fixedCoordinateSpace.bounds.width : geometry.size.height)
            .background(Color.black)
            .edgesIgnoringSafeArea(isFullScreen ? .all : [])
            .statusBarHidden(isFullScreen)
            .onChange(of: isFullScreen, perform: changeOrientation)
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                isFullScreen = UIDevice.current.orientation.isLandscape
            }
        }
    }
    
    func changeOrientation(isFullscreen: Bool){
        let currentOrientation = UIDevice.current.orientation
        if isFullscreen && currentOrientation.isLandscape || !isFullscreen && currentOrientation.isPortrait  {
            return
        }
        
        let orientation: UIInterfaceOrientationMask = isFullscreen ? .landscapeRight : .portrait
        if #available(iOS 16.0, *) {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
        } else {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        }
    }
}
