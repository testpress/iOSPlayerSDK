import SwiftUI

@available(iOS 13.0, *)
struct PlayerSettingsButton: View {
    @State private var showOptions = false
    @State private var currentMenu: SettingsMenu = .main
    private var enableDownload: Bool = false
    
    @EnvironmentObject var player: TPStreamPlayerObservable
    
    init(enableDownload: Bool) {
        self.enableDownload = enableDownload
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
                buttons: getButtons()
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
    
    private func getButtons() -> [ActionSheet.Button] {
        var buttons = [playbackSpeedButton(), videoQualityButton()]
        if enableDownload {
            buttons.append(downloadQualityButton())
        }
        buttons.append(.cancel())
        return buttons
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
                        TPStreamsDownloadManager.shared.startDownload(asset: player.asset!, bitRate: downloadQuality.bitrate)
                    }
            }
        }
}

enum SettingsMenu { case main, playbackSpeed, videoQuality, downloadQuality }
