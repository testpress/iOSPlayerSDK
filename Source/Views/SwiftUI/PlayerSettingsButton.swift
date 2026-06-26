import SwiftUI

@available(iOS 13.0, *)
struct PlayerSettingsButton: View {
    @State private var showOptions = false
    @State private var currentMenu: SettingsMenu = .main
    
    @EnvironmentObject var player: TPStreamPlayerObservable
    private var playerConfig: TPStreamPlayerConfiguration
    @Binding private var activeSubtitleTrack: SubtitleTrack?
    
    init(playerConfig: TPStreamPlayerConfiguration, activeSubtitleTrack: Binding<SubtitleTrack?>){
        self.playerConfig = playerConfig
        _activeSubtitleTrack = activeSubtitleTrack
    }
    
    var body: some View {
        HStack {
            Spacer()
            if playerConfig.showSettingsButton {
                Button(action: {
                    showOptions = true
                    currentMenu = .main
                }) {
                    Image("settings", bundle: bundle)
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .padding([.trailing, .top], 12)
                .actionSheet(isPresented: $showOptions, content: settingsActionSheet)
            }
        }
    }
    
    private func settingsActionSheet() -> ActionSheet {
        switch currentMenu {
        case .main:
            return ActionSheet(
                title: Text("Settings"),
                message: nil,
                buttons: getMainActionSheetButtons()
            )
        case .playbackSpeed:
            return ActionSheet(
                title: Text("Playback Speed"),
                message: nil,
                buttons: playbackSpeedOptions() + [.cancel()]
            )
        case .videoQuality:
            return ActionSheet(
                title: Text("Video Quality"),
                message: Text("Video quality adjusts based on your internet speed. Your selection sets the highest possible quality."),
                buttons: videoQualityOptions() + [.cancel()]
            )
        case .downloadQuality:
            return ActionSheet(
                title: Text("Download Quality"),
                message: nil,
                buttons: downloadQualityOptions() + [.cancel()]
            )
        case .captions:
            return ActionSheet(
                title: Text("Captions"),
                message: nil,
                buttons: captionsOptions() + [.cancel()]
            )
        }
    }
    
    private func getMainActionSheetButtons() -> [ActionSheet.Button] {
        var actionButtons: [ActionSheet.Button] = []
        
        if playerConfig.enablePlaybackSpeed {
             actionButtons.append(playbackSpeedButton())
        }
        
        if playerConfig.enableCaptions, let tracks = player.asset?.video?.tracks, !tracks.isEmpty {
            actionButtons.append(captionsButton())
        }
        
        if !player.player.isPlaybackOffline {
            addOnlinePlaybackButtons(to: &actionButtons)
        }
        
        actionButtons.append(.cancel())
        
        return actionButtons
    }

    private func addOnlinePlaybackButtons(to buttons: inout [ActionSheet.Button]) {
        if playerConfig.showResolutionOptions {
            buttons.append(videoQualityButton())
        }
        
        if playerConfig.showDownloadOption {
            buttons.append(downloadQualityButton())
        }
    }
    
    private func playbackSpeedButton() -> ActionSheet.Button {
        return .default(Text("Playback Speed - \(player.observedCurrentPlaybackSpeed.label)")) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showOptions = true
                self.currentMenu = .playbackSpeed
            }
        }
    }
    
    private func videoQualityButton() -> ActionSheet.Button {
        let currentLabel = player.currentVideoQuality.map { VideoQualityUtils.getDisplayLabel(for: $0) } ?? "Auto"

        return .default(Text("Video Quality - \(currentLabel)")) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showOptions = true
                self.currentMenu = .videoQuality
            }
        }
    }
    
    private func downloadQualityButton() -> ActionSheet.Button {
        return .default(Text("Download")) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showOptions = true
                self.currentMenu = .downloadQuality
            }
        }
    }
    
    private func captionsButton() -> ActionSheet.Button {
        let currentLabel = activeSubtitleTrack?.displayName ?? "Off"
        return .default(Text("Captions - \(currentLabel)")) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showOptions = true
                self.currentMenu = .captions
            }
        }
    }
    
    private func captionsOptions() -> [ActionSheet.Button] {
        guard let tracks = player.asset?.video?.tracks else { return [] }
        var buttons: [ActionSheet.Button] = []
        
        // Add "Off" option with selection indicator
        let isOffSelected = activeSubtitleTrack == nil
        let offLabel = isOffSelected ? "✓ Off" : "Off"
        let offAction = ActionSheet.Button.default(Text(offLabel)) {
            activeSubtitleTrack = nil
        }
        buttons.append(offAction)
        
        // Add each track option with selection indicator
        for track in tracks {
            let isSelected = track.url == activeSubtitleTrack?.url
            let label = isSelected ? "✓ \(track.displayName)" : track.displayName
            let action = ActionSheet.Button.default(Text(label)) {
                activeSubtitleTrack = track
            }
            buttons.append(action)
        }
        
        return buttons
    }
    
    private func playbackSpeedOptions() -> [ActionSheet.Button] {
        let playbackSpeeds = PlaybackSpeed.allCases
        return playbackSpeeds.map { speed in
                .default(Text(speed.label)) {
                    player.changePlaybackSpeed(speed)
                }
        }
    }
    
    private func videoQualityOptions() -> [ActionSheet.Button] {
        return player.availableVideoQualities.map { videoQuality in
                .default(Text(VideoQualityUtils.getDisplayLabel(for: videoQuality))) {
                    player.changeVideoQuality(videoQuality)
                }
        }
    }
    
    private func downloadQualityOptions() -> [ActionSheet.Button] {
        var availableVideoQualities = player.availableVideoQualities
        // Remove Auto Quality from the Array
        availableVideoQualities.remove(at: 0)
        return availableVideoQualities.map { downloadQuality in
                .default(Text(downloadQuality.resolution)) {
                    do {
                        try TPStreamsDownloadManager.shared.enqueueDownload(
                            asset: player.asset!, 
                            accessToken: player.player.accessToken, 
                            videoQuality: downloadQuality,
                            metadata: playerConfig.downloadMetadata,
                            offlineLicenseDurationSeconds: playerConfig.licenseDurationSeconds
                        )
                    } catch {
                        print("Error downloading video: \(error)")
                    }
                }
        }
    }
}

enum SettingsMenu { case main, playbackSpeed, videoQuality, downloadQuality, captions }
