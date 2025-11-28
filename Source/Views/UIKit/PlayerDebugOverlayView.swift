//
//  PlayerDebugOverlayView.swift
//  TPStreamsSDK
//
//  Created for debug timeline overlay
//

import UIKit

class PlayerDebugOverlayView: UIView {
    private var tracker: PlayerTimelineTracker?
    private var updateTimer: Timer?
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Player Timeline"
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var drmLabel: UILabel = {
        let label = UILabel()
        label.text = "DRM"
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .yellow
        label.backgroundColor = UIColor.yellow.withAlphaComponent(0.2)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(drmLabel)
        containerView.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            containerView.widthAnchor.constraint(equalToConstant: 280),
            containerView.heightAnchor.constraint(lessThanOrEqualToConstant: 400),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            
            drmLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            drmLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            drmLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            drmLabel.heightAnchor.constraint(equalToConstant: 18),
            drmLabel.widthAnchor.constraint(equalToConstant: 40),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        drmLabel.isHidden = true
    }
    
    func setTracker(_ tracker: PlayerTimelineTracker) {
        self.tracker = tracker
        drmLabel.isHidden = !tracker.isDRM
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
        updateDisplay()
    }
    
    private func updateDisplay() {
        guard let tracker = tracker else { return }
        
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Initial Steps
        if let fetch = tracker.assetFetchDuration {
            addRow(label: "Asset Fetch", value: String(format: "%.2fs", fetch))
        }
        
        if let item = tracker.playerItemCreationDuration {
            addRow(label: "Player Item Created", value: String(format: "%.2fs", item))
        }
        
        // DRM Steps
        if tracker.isDRM {
            if let drmSetup = tracker.drmSetupDuration {
                addRow(label: "DRM Setup", value: String(format: "%.2fs", drmSetup))
            }
            
            if let license = tracker.drmLicenseRequestDuration {
                addRow(label: "DRM License", value: String(format: "%.2fs", license), isDelay: true)
            }
        }
        
        if let setup = tracker.setupDuration {
            addRow(label: "Setup Complete", value: String(format: "%.2fs", setup))
        }
        
        if let ready = tracker.playerReadyDuration {
            addRow(label: "Player Ready", value: String(format: "%.2fs", ready))
        }
        
        if let buffer = tracker.firstBufferReadyDuration {
            addRow(label: "First Buffer Ready", value: String(format: "%.2fs", buffer))
        }
        
        if let fewSeconds = tracker.firstFewSecondsBufferedDuration {
            addRow(label: "3s Buffered", value: String(format: "%.2fs", fewSeconds))
        }
        
        if let playback = tracker.playbackStartDuration {
            addRow(label: "Playback Started", value: String(format: "%.2fs", playback))
        }
        
        // Delays Section
        if tracker.setupToPlayerReadyDelay != nil ||
           tracker.playerReadyToFirstBufferDelay != nil ||
           tracker.firstBufferToPlaybackDelay != nil ||
           tracker.setupToPlaybackDelay != nil ||
           tracker.readyToPlaybackDelay != nil {
            addDivider()
            addSectionHeader("Delays")
        }
        
        if let delay = tracker.setupToPlayerReadyDelay {
            addRow(label: "Setup → Ready", value: String(format: "%.2fs", delay), isDelay: true)
        }
        
        if let delay = tracker.playerReadyToFirstBufferDelay {
            addRow(label: "Ready → Buffer", value: String(format: "%.2fs", delay), isDelay: true)
        }
        
        if let delay = tracker.firstBufferToPlaybackDelay {
            addRow(label: "Buffer → Playback", value: String(format: "%.2fs", delay), isDelay: true)
        }
        
        if let delay = tracker.setupToPlaybackDelay {
            addRow(label: "Setup → Playback", value: String(format: "%.2fs", delay), isDelay: true)
        }
        
        if let delay = tracker.readyToPlaybackDelay {
            addRow(label: "Ready → Playback", value: String(format: "%.2fs", delay), isDelay: true)
        }
    }
    
    private func addDivider() {
        let divider = UIView()
        divider.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stackView.addArrangedSubview(divider)
    }
    
    private func addSectionHeader(_ text: String) {
        let header = UILabel()
        header.text = text
        header.font = .systemFont(ofSize: 11, weight: .semibold)
        header.textColor = .yellow.withAlphaComponent(0.9)
        header.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(header)
    }
    
    private func addRow(label: String, value: String, isDelay: Bool = false) {
        let rowView = UIView()
        rowView.translatesAutoresizingMaskIntoConstraints = false
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 11)
        labelView.textColor = .white.withAlphaComponent(0.8)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        let valueView = UILabel()
        valueView.text = value
        valueView.font = .systemFont(ofSize: 11, weight: isDelay ? .semibold : .regular)
        valueView.textColor = isDelay ? .yellow : .white
        valueView.translatesAutoresizingMaskIntoConstraints = false
        
        rowView.addSubview(labelView)
        rowView.addSubview(valueView)
        
        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: rowView.leadingAnchor),
            labelView.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            
            valueView.trailingAnchor.constraint(equalTo: rowView.trailingAnchor),
            valueView.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            valueView.leadingAnchor.constraint(greaterThanOrEqualTo: labelView.trailingAnchor, constant: 8),
            
            rowView.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        stackView.addArrangedSubview(rowView)
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}

