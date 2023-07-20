import SwiftUI

@available(iOS 13.0, *)
struct PlayerSettingsButton: View {
    @State private var showOptions = false
    @State private var currentMenu: SettingsMenu = .main
    
    @EnvironmentObject var player: TPStreamPlayer
    
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
                buttons: [playbackSpeedButton(), videoQualityButton(), .cancel()]
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
}

enum SettingsMenu { case main, playbackSpeed, videoQuality }
