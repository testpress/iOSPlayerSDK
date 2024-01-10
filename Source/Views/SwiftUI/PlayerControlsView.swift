import SwiftUI

@available(iOS 14.0, *)
struct PlayerControlsView: View {
    @StateObject private var player: TPStreamPlayerObservable
    @State private var showControls = false
    @State private var controlsHideTimer: Timer?
    @Binding private var isFullscreen: Bool
    private var enableDownload: Bool = false
    
    init(player: TPAVPlayer, isFullscreen: Binding<Bool>, enableDownload: Bool){
        _player = StateObject(wrappedValue: TPStreamPlayerObservable(player: player))
        _isFullscreen = isFullscreen
        self.enableDownload = enableDownload
    }
    
    var body: some View {
        VStack{
            if showControls {
                PlayerSettingsButton(enableDownload: enableDownload)
                Spacer()
                MediaControlsView()
                Spacer()
                HStack {
                    TimeIndicatorView()
                    Spacer()
                    fullscreenButton()
                }.padding(.horizontal, 10)
                PlayerProgressBar()
                    .padding(.bottom, isFullscreen ? 36 : 0)
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

@available(iOS 14.0.0, *)
struct TPVideoPlayerControls_Previews: PreviewProvider {
    static var previews: some View {
        PlayerControlsView(
            player: TPAVPlayer(
                assetID: "dummy",
                accessToken: "dummy"
            ),
            isFullscreen: .constant(true),
            enableDownload: true
        ).background(Color.black)
    }
}
