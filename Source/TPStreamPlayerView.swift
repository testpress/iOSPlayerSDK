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
            let isFullScreen = viewModel.isFullScreen
            let horizontalPadding: CGFloat = isFullScreen ? 48 : 0
            let contentWidth = (isFullScreen
                ? UIScreen.main.fixedCoordinateSpace.bounds.height
                : geometry.size.width) - horizontalPadding * 2
            let contentHeight = isFullScreen
                ? UIScreen.main.fixedCoordinateSpace.bounds.width
                : geometry.size.height

            ZStack {
                if let message = viewModel.noticeMessage {
                    NoticeView(message: message)
                } else if viewModel.player.initializationStatus == "ready" {
                    AVPlayerBridge(player: viewModel.player)
                    
                    WatermarkOverlayViewRepresentable(
                        watermarks: playerViewConfig.watermarks,
                        reservedBottomHeight: playerViewConfig.enableCaptions && activeSubtitleTrack != nil
                            ? SubtitleView.reservedBottomBandHeight
                            : 0,
                        labelsAreFrozen: playerObservable.observedStatus != "playing",
                        watermarkContentRect: Self.calculateVideoRect(
                            player: viewModel.player,
                            containerSize: CGSize(width: contentWidth, height: contentHeight)
                        )
                    )
                    
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
            .padding(.horizontal, horizontalPadding)
            .frame(width: contentWidth + horizontalPadding * 2,
                   height: contentHeight)
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

    private static func calculateVideoRect(
        player: TPAVPlayer,
        containerSize: CGSize
    ) -> CGRect {
        guard let videoSize = extractVideoSize(from: player) else { return .zero }
        return VideoRectCalculator.calculate(videoSize: videoSize, containerSize: containerSize)
    }

    private static func extractVideoSize(from player: TPAVPlayer) -> CGSize? {
        guard let track = player.currentItem?.asset.tracks(withMediaType: .video).first else {
            return nil
        }
        let transformed = track.naturalSize.applying(track.preferredTransform)
        let size = CGSize(width: abs(transformed.width), height: abs(transformed.height))
        return (size.width > 0 && size.height > 0) ? size : nil
    }
}
