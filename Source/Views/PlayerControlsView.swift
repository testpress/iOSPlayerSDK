import SwiftUI

let bundle = Bundle(identifier: "com.tpstreams.iOSPlayerSDK")

struct PlayerControlsView: View {
    @StateObject private var player: TPStreamPlayer
    @State private var showControls = false
    @State private var controlsHideTimer: Timer?
    @Binding private var isFullscreen: Bool
    
    init(player: TPAVPlayer, isFullscreen: Binding<Bool>){
        _player = StateObject(wrappedValue: TPStreamPlayer(player: player))
        self._isFullscreen = isFullscreen
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
                    fullscreenButton()
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
    
    func fullscreenButton() -> some View{
        return Button(action: {isFullscreen.toggle()}) {
            Image(isFullscreen ? "minimize": "maximize", bundle: bundle)
                .resizable()
                .frame(width: 16, height: 16)
        }
    }
}

struct TPVideoPlayerControls_Previews: PreviewProvider {
    static var previews: some View {
        PlayerControlsView(
            player: TPAVPlayer(
                assetID: "dummy",
                accessToken: "dummy"
            ),
            isFullscreen: .constant(true)
        ).background(Color.black)
    }
}
