//
//  TPStreamPlayer.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 31/05/23.
//

import SwiftUI

@available(iOS 14.0, *)
public struct TPStreamPlayerView: View {
    @StateObject private var viewModel: TPStreamPlayerViewModel
    @StateObject private var playerObservable: TPStreamPlayerObservable
    @State private var activeSubtitleTrack: SubtitleTrack?
    private var playerViewConfig: TPStreamPlayerConfiguration
    
    public init(player: TPAVPlayer, playerViewConfig: TPStreamPlayerConfiguration = TPStreamPlayerConfigurationBuilder().build()) {
        _viewModel = StateObject(wrappedValue: TPStreamPlayerViewModel(player: player))
        _playerObservable = StateObject(wrappedValue: TPStreamPlayerObservable(player: player, userId: playerViewConfig.userId))
        self.playerViewConfig = playerViewConfig
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let message = viewModel.noticeMessage {
                    NoticeView(message: message)
                } else if viewModel.player.initializationStatus == "ready" {
                    AVPlayerBridge(player: viewModel.player)
                    
                    if playerViewConfig.enableCaptions, let activeSubtitleTrack = activeSubtitleTrack {
                        SubtitleTextView(
                            track: activeSubtitleTrack,
                            currentTime: playerObservable.observedCurrentTime,
                            isFullScreen: viewModel.isFullScreen
                        )
                    }
                    
                    PlayerControlsView(
                        isFullscreen: $viewModel.isFullScreen,
                        playerViewConfig: playerViewConfig,
                        activeSubtitleTrack: $activeSubtitleTrack
                    )
                    .environmentObject(playerObservable)
                }
            }
            .padding(.horizontal, viewModel.isFullScreen ? 48 : 0)
            .frame(width: viewModel.isFullScreen ? UIScreen.main.fixedCoordinateSpace.bounds.height : geometry.size.width,
                   height: viewModel.isFullScreen ? UIScreen.main.fixedCoordinateSpace.bounds.width : geometry.size.height)
            .background(Color.black)
            .edgesIgnoringSafeArea(viewModel.isFullScreen ? .all : [])
            .statusBarHidden(viewModel.isFullScreen)
            .onChange(of: viewModel.isFullScreen, perform: changeOrientation)
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                viewModel.isFullScreen = UIDevice.current.orientation.isLandscape
            }
            .onAppear {
                if self.playerViewConfig.startInFullscreen {
                    changeOrientation(isFullscreen: true)
                }
            }
            .onChange(of: viewModel.player.initializationStatus) { newStatus in
                if newStatus == "ready" && activeSubtitleTrack == nil && playerViewConfig.autoSelectFirstSubtitle && playerViewConfig.enableCaptions {
                    if let firstTrack = viewModel.player.asset?.video?.tracks.first {
                        activeSubtitleTrack = firstTrack
                    }
                }
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
            UIDevice.current.setValue(orientation.toUIInterfaceOrientation.rawValue, forKey: "orientation")
        }
    }
}
