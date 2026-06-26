import SwiftUI

@available(iOS 14.0, *)
struct SubtitleTextView: UIViewRepresentable {
  let track: SubtitleTrack
  let currentTime: Float64?

  func makeUIView(context: Context) -> SubtitleView {
    let view = SubtitleView(frame: .zero)
    return view
  }

  func updateUIView(_ uiView: SubtitleView, context: Context) {
    uiView.setTrack(track)

    if let currentTime = currentTime {
      uiView.updateSubtitle(at: currentTime)
    }
  }
}
