//
//  PlayerTimelineTracker.swift
//  TPStreamsSDK
//
//  Created for timeline tracking
//

import Foundation

class PlayerTimelineTracker {
    private var startTime: Date
    private var assetFetchStartTime: Date?
    private var assetFetchEndTime: Date?
    private var playerItemCreatedTime: Date?
    private var drmSetupStartTime: Date?
    private var drmLicenseRequestStartTime: Date?
    private var drmLicenseResolvedTime: Date?
    private var setupCompletedTime: Date?
    private var playerReadyTime: Date?
    private var firstBufferReadyTime: Date?
    private var playbackStartedTime: Date?
    private var firstFewSecondsBufferedTime: Date?
    
    var isDRM: Bool = false
    private var hasTrackedFirstBuffer: Bool = false
    private var hasTrackedFirstFewSeconds: Bool = false
    
    init() {
        self.startTime = Date()
    }
    
    func markAssetFetchStart() {
        assetFetchStartTime = Date()
    }
    
    func markAssetFetchEnd() {
        assetFetchEndTime = Date()
    }
    
    func markPlayerItemCreated() {
        playerItemCreatedTime = Date()
    }
    
    func markDRMSetupStart() {
        drmSetupStartTime = Date()
    }
    
    func markDRMLicenseRequestStart() {
        drmLicenseRequestStartTime = Date()
    }
    
    func markDRMLicenseResolved() {
        drmLicenseResolvedTime = Date()
    }
    
    func markSetupCompleted() {
        setupCompletedTime = Date()
    }
    
    func markPlayerReady() {
        playerReadyTime = Date()
    }
    
    func markFirstBufferReady() {
        if !hasTrackedFirstBuffer {
            firstBufferReadyTime = Date()
            hasTrackedFirstBuffer = true
        }
    }
    
    func markPlaybackStarted() {
        if playbackStartedTime == nil {
            playbackStartedTime = Date()
        }
    }
    
    func markFirstFewSecondsBuffered() {
        if !hasTrackedFirstFewSeconds {
            firstFewSecondsBufferedTime = Date()
            hasTrackedFirstFewSeconds = true
        }
    }
    
    // Duration from start
    var assetFetchDuration: Double? {
        guard let endTime = assetFetchEndTime else { return nil }
        return endTime.timeIntervalSince(assetFetchStartTime ?? startTime)
    }
    
    var playerItemCreationDuration: Double? {
        guard let itemTime = playerItemCreatedTime else { return nil }
        return itemTime.timeIntervalSince(startTime)
    }
    
    var drmSetupDuration: Double? {
        guard let setupTime = drmSetupStartTime else { return nil }
        let endTime = drmLicenseResolvedTime ?? setupCompletedTime ?? Date()
        return endTime.timeIntervalSince(setupTime)
    }
    
    var drmLicenseRequestDuration: Double? {
        guard let requestTime = drmLicenseRequestStartTime,
              let resolvedTime = drmLicenseResolvedTime else { return nil }
        return resolvedTime.timeIntervalSince(requestTime)
    }
    
    var setupDuration: Double? {
        guard let setupTime = setupCompletedTime else { return nil }
        return setupTime.timeIntervalSince(startTime)
    }
    
    var playerReadyDuration: Double? {
        guard let readyTime = playerReadyTime else { return nil }
        return readyTime.timeIntervalSince(startTime)
    }
    
    var firstBufferReadyDuration: Double? {
        guard let bufferTime = firstBufferReadyTime else { return nil }
        return bufferTime.timeIntervalSince(startTime)
    }
    
    var playbackStartDuration: Double? {
        guard let playbackTime = playbackStartedTime else { return nil }
        return playbackTime.timeIntervalSince(startTime)
    }
    
    var firstFewSecondsBufferedDuration: Double? {
        guard let bufferedTime = firstFewSecondsBufferedTime else { return nil }
        return bufferedTime.timeIntervalSince(startTime)
    }
    
    // Delays between steps
    var assetFetchToPlayerItemDelay: Double? {
        guard let fetchEnd = assetFetchEndTime,
              let itemTime = playerItemCreatedTime else { return nil }
        return itemTime.timeIntervalSince(fetchEnd)
    }
    
    var playerItemToDRMSetupDelay: Double? {
        guard let itemTime = playerItemCreatedTime,
              let drmStart = drmSetupStartTime else { return nil }
        return drmStart.timeIntervalSince(itemTime)
    }
    
    var drmSetupToLicenseRequestDelay: Double? {
        guard let drmStart = drmSetupStartTime,
              let licenseStart = drmLicenseRequestStartTime else { return nil }
        return licenseStart.timeIntervalSince(drmStart)
    }
    
    var setupToPlayerReadyDelay: Double? {
        guard let setupTime = setupCompletedTime,
              let readyTime = playerReadyTime else { return nil }
        return readyTime.timeIntervalSince(setupTime)
    }
    
    var playerReadyToFirstBufferDelay: Double? {
        guard let readyTime = playerReadyTime,
              let bufferTime = firstBufferReadyTime else { return nil }
        return bufferTime.timeIntervalSince(readyTime)
    }
    
    var firstBufferToPlaybackDelay: Double? {
        guard let bufferTime = firstBufferReadyTime,
              let playbackTime = playbackStartedTime else { return nil }
        return playbackTime.timeIntervalSince(bufferTime)
    }
    
    var setupToPlaybackDelay: Double? {
        guard let setupTime = setupCompletedTime,
              let playbackTime = playbackStartedTime else { return nil }
        return playbackTime.timeIntervalSince(setupTime)
    }
    
    var readyToPlaybackDelay: Double? {
        guard let readyTime = playerReadyTime,
              let playbackTime = playbackStartedTime else { return nil }
        return playbackTime.timeIntervalSince(readyTime)
    }
}

