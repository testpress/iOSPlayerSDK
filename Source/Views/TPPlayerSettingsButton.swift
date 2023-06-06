import SwiftUI

struct TPPlayerSettingsButton: View {
    @State private var showOptions = false
    @State private var optionsMenu: OptionsMenu = .main
    
    @EnvironmentObject var player: TPStreamPlayer
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                showOptions = true
                optionsMenu = .main
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
        switch optionsMenu {
        case .main:
            return ActionSheet(
                title: Text("Settings"),
                message: nil,
                buttons: [playbackSpeedButton(), .cancel()]
            )
        case .playbackSpeed:
            return ActionSheet(
                title: Text("Playback Speed"),
                message: nil,
                buttons: playbackSpeedOptions() + [.cancel()]
            )
        }
    }
    
    private func playbackSpeedButton() -> ActionSheet.Button {
        return .default(Text("Playback Speed - \(player.currentPlaybackSpeed.label)")) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showOptions = true
                self.optionsMenu = .playbackSpeed
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
}

enum OptionsMenu { case main, playbackSpeed }
