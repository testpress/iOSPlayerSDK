import SwiftUI

let bundle = Bundle(identifier: "com.tpstreams.iOSPlayerSDK")

struct TPVideoPlayerControls: View {
    @StateObject private var player: TPStreamPlayer
    @State private var showControls = false
    @State private var hideTimer: Timer?
    
    init(player: TPAVPlayer){
        _player = StateObject(wrappedValue: TPStreamPlayer(player: player))
    }
        
    var body: some View {
        VStack{
            if showControls {
                Spacer()
                Button(action: player.togglePlay) {
                    Image(player.status == .paused ? "play" : "pause", bundle: bundle)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .brightness(-0.1)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(showControls ? Color.black.opacity(0.3) : Color.black.opacity(0.0001))
        .onTapGesture {
            showControls.toggle()
            if showControls {
                startHideTimer()
            }
        }
    }
    
    private func startHideTimer() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            showControls = false
        }
    }
}

struct TPVideoPlayerControls_Previews: PreviewProvider {
    static var previews: some View {
        TPVideoPlayerControls(
            player: TPAVPlayer(
                assetID: "dummy",
                accessToken: "dummy"
            )
        ).background(Color.black)
    }
}
