import SwiftUI

struct PlayerProgressBar: View {
    @EnvironmentObject var player: TPStreamPlayer
    @State private var isDragging = false
    @State private var draggedLocation: Float64?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.5))
                    .frame(width: geometry.size.width, height: 2.5)
                
                Rectangle()
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(width: CGFloat(
                        calculateWidthForValue(value: player.bufferedDuration, geometry: geometry)), height: 2.5)
                
                Rectangle()
                    .foregroundColor(Color.red)
                    .frame(width: CGFloat(calculateWidthForValue(value: player.currentTime ?? 0, geometry: geometry)), height: 2.5)
                
                
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .scaleEffect(isDragging ? 1.8 : 1.0)
                    .offset(x: isDragging ? draggedLocation! : calculateWidthForValue(value: player.currentTime ?? 0, geometry: geometry))
                    .gesture(DragGesture()
                        .onChanged(handleThumbDrag)
                        .onEnded { value in
                            seekToDraggedLocation(value: value, geometry: geometry)
                        }
                    )
            }
            .frame(height: 3)
        }.frame(height: 3)
    }
    
    private func calculateWidthForValue(value: Float64, geometry: GeometryProxy) -> CGFloat {
        let totalWidth = geometry.size.width
        let percentage = CGFloat(value / player.videoDuration).isNaN ? 0.001 : CGFloat(value / player.videoDuration)
        return totalWidth * percentage
    }
    
    private func handleThumbDrag(value: DragGesture.Value){
        isDragging = true
        draggedLocation = Double(value.location.x)
    }
    
    private func seekToDraggedLocation(value: DragGesture.Value, geometry: GeometryProxy){
        let seconds = getSecondsForDraggedLocation(geometry)
        player.goTo(seconds: seconds)
        isDragging = false
    }
    
    private func getSecondsForDraggedLocation(_ geometry: GeometryProxy) -> Float64{
        let totalWidth = Float64(geometry.size.width)
        let percentage = draggedLocation! / totalWidth
        return player.videoDuration * percentage
    }
}
