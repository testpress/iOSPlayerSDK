import SwiftUI

@available(iOS 13.0, *)
struct PlayerSettingsButton: View {
    @State private var showOptions = false
    @State private var currentMenu: SettingsMenu = .main
    
    @EnvironmentObject var player: TPStreamPlayerObservable
    private var playerConfig: TPStreamPlayerConfiguration
    
    init(playerConfig: TPStreamPlayerConfiguration){
        self.playerConfig = playerConfig
    }
    
    var body: some View {
        HStack {
            Spacer()
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
                message: nil,
                buttons: videoQualityOptions() + [.cancel()]
            )
        case .downloadQuality:
            return ActionSheet(
                title: Text("Download Quality"),
                message: nil,
                buttons: downloadQualityOptions() + [.cancel()]
            )
        }
    }
    
    private func getMainActionSheetButtons() -> [ActionSheet.Button] {
        var actionButtons: [ActionSheet.Button] = [playbackSpeedButton()]
        
        if !player.player.isPlaybackOffline {
            addOnlinePlaybackButtons(to: &actionButtons)
        }
        
        actionButtons.append(.cancel())
        
        return actionButtons
    }

    private func addOnlinePlaybackButtons(to buttons: inout [ActionSheet.Button]) {
        buttons.append(videoQualityButton())
        
        if playerConfig.showDownloadOption {
            buttons.append(downloadQualityButton())
        }
    }
    
    private func playbackSpeedButton() -> ActionSheet.Button {
        return .default(Text("Playback Speed - \(player.currentPlaybackSpeed.label)")) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showOptions = true
                self.currentMenu = .playbackSpeed
            }
        }
    }
    
    private func videoQualityButton() -> ActionSheet.Button {
        return .default(Text("Video Quality - \(player.currentVideoQuality?.resolution ?? "Auto")")) {
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
                .default(Text(videoQuality.resolution)) {
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
                    TPStreamsDownloadManager.shared.startDownload(player: player.player, videoQuality: downloadQuality)
                }
        }
    }
}

enum SettingsMenu { case main, playbackSpeed, videoQuality, downloadQuality }
