//
//  PlayerDebugOverlay.swift
//  TPStreamsSDK
//
//  Created for debug timeline overlay
//

import SwiftUI

@available(iOS 14.0, *)
struct PlayerDebugOverlay: View {
    @ObservedObject var tracker: PlayerTimelineTrackerObservable
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Player Timeline")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if tracker.isDRM {
                        Text("DRM")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // Initial Steps
                if let fetch = tracker.assetFetchDuration {
                    TimelineRow(label: "Asset Fetch", value: String(format: "%.2fs", fetch))
                }
                
                if let item = tracker.playerItemCreationDuration {
                    TimelineRow(label: "Player Item Created", value: String(format: "%.2fs", item))
                }
                
                // DRM Steps
                if tracker.isDRM {
                    if let drmSetup = tracker.drmSetupDuration {
                        TimelineRow(label: "DRM Setup", value: String(format: "%.2fs", drmSetup))
                    }
                    
                    if let license = tracker.drmLicenseRequestDuration {
                        TimelineRow(label: "DRM License", value: String(format: "%.2fs", license), isDelay: true)
                    }
                }
                
                if let setup = tracker.setupDuration {
                    TimelineRow(label: "Setup Complete", value: String(format: "%.2fs", setup))
                }
                
                if let ready = tracker.playerReadyDuration {
                    TimelineRow(label: "Player Ready", value: String(format: "%.2fs", ready))
                }
                
                if let buffer = tracker.firstBufferReadyDuration {
                    TimelineRow(label: "First Buffer Ready", value: String(format: "%.2fs", buffer))
                }
                
                if let fewSeconds = tracker.firstFewSecondsBufferedDuration {
                    TimelineRow(label: "3s Buffered", value: String(format: "%.2fs", fewSeconds))
                }
                
                if let playback = tracker.playbackStartDuration {
                    TimelineRow(label: "Playback Started", value: String(format: "%.2fs", playback))
                }
                
                // Delays
                Divider()
                    .background(Color.white.opacity(0.3))
                    .padding(.top, 4)
                
                Text("Delays")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.yellow.opacity(0.9))
                
                if let delay = tracker.setupToPlayerReadyDelay {
                    TimelineRow(label: "Setup → Ready", value: String(format: "%.2fs", delay), isDelay: true)
                }
                
                if let delay = tracker.playerReadyToFirstBufferDelay {
                    TimelineRow(label: "Ready → Buffer", value: String(format: "%.2fs", delay), isDelay: true)
                }
                
                if let delay = tracker.firstBufferToPlaybackDelay {
                    TimelineRow(label: "Buffer → Playback", value: String(format: "%.2fs", delay), isDelay: true)
                }
                
                if let delay = tracker.setupToPlaybackDelay {
                    TimelineRow(label: "Setup → Playback", value: String(format: "%.2fs", delay), isDelay: true)
                }
                
                if let delay = tracker.readyToPlaybackDelay {
                    TimelineRow(label: "Ready → Playback", value: String(format: "%.2fs", delay), isDelay: true)
                }
            }
            .padding(8)
        }
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
        .padding(8)
        .frame(maxWidth: 280, maxHeight: 400, alignment: .topLeading)
    }
}

@available(iOS 14.0, *)
struct TimelineRow: View {
    let label: String
    let value: String
    var isDelay: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: isDelay ? .semibold : .regular))
                .foregroundColor(isDelay ? .yellow : .white)
        }
    }
}

@available(iOS 14.0, *)
class PlayerTimelineTrackerObservable: ObservableObject {
    private let tracker: PlayerTimelineTracker
    private var updateTimer: Timer?
    
    @Published var assetFetchDuration: Double?
    @Published var playerItemCreationDuration: Double?
    @Published var drmSetupDuration: Double?
    @Published var drmLicenseRequestDuration: Double?
    @Published var setupDuration: Double?
    @Published var playerReadyDuration: Double?
    @Published var firstBufferReadyDuration: Double?
    @Published var firstFewSecondsBufferedDuration: Double?
    @Published var playbackStartDuration: Double?
    @Published var setupToPlayerReadyDelay: Double?
    @Published var playerReadyToFirstBufferDelay: Double?
    @Published var firstBufferToPlaybackDelay: Double?
    @Published var setupToPlaybackDelay: Double?
    @Published var readyToPlaybackDelay: Double?
    @Published var isDRM: Bool = false
    
    init(tracker: PlayerTimelineTracker) {
        self.tracker = tracker
        self.isDRM = tracker.isDRM
        updateValues()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateValues()
        }
    }
    
    func updateValues() {
        assetFetchDuration = tracker.assetFetchDuration
        playerItemCreationDuration = tracker.playerItemCreationDuration
        drmSetupDuration = tracker.drmSetupDuration
        drmLicenseRequestDuration = tracker.drmLicenseRequestDuration
        setupDuration = tracker.setupDuration
        playerReadyDuration = tracker.playerReadyDuration
        firstBufferReadyDuration = tracker.firstBufferReadyDuration
        firstFewSecondsBufferedDuration = tracker.firstFewSecondsBufferedDuration
        playbackStartDuration = tracker.playbackStartDuration
        setupToPlayerReadyDelay = tracker.setupToPlayerReadyDelay
        playerReadyToFirstBufferDelay = tracker.playerReadyToFirstBufferDelay
        firstBufferToPlaybackDelay = tracker.firstBufferToPlaybackDelay
        setupToPlaybackDelay = tracker.setupToPlaybackDelay
        readyToPlaybackDelay = tracker.readyToPlaybackDelay
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}

