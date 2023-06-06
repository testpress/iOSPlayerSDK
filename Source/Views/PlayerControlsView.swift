import SwiftUI

let bundle = Bundle(identifier: "com.tpstreams.iOSPlayerSDK")

struct PlayerControlsView: View {
    @StateObject private var player: TPStreamPlayer
    @State private var showControls = false
    @State private var controlsHideTimer: Timer?
    
    init(player: TPAVPlayer){
        _player = StateObject(wrappedValue: TPStreamPlayer(player: player))
    }
        
    var body: some View {
        VStack{
            if showControls {
                PlayerSettingsButton()
                Spacer()
                MediaControlsView()
                Spacer()
                HStack {
                    TimeIndicatorView()
                    Spacer()
                }.padding([.horizontal, .bottom], 10)
            }
        }
        .environmentObject(player)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(showControls ? Color.black.opacity(0.3) : Color.black.opacity(0.0001))
        .onTapGesture {
            showControls.toggle()
            if showControls {
                scheduleTimerToHideControls()
            }
        }
    }
    
    private func scheduleTimerToHideControls() {
        controlsHideTimer?.invalidate()
        controlsHideTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
            showControls = false
        }
    }
}

struct TPVideoPlayerControls_Previews: PreviewProvider {
    static var previews: some View {
        PlayerControlsView(
            player: TPAVPlayer(
                assetID: "dummy",
                accessToken: "dummy"
            )
        ).background(Color.black)
    }
}
