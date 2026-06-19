import UIKit
import SwiftSubtitles

class SubtitleView: UIView {
    private let container = UIView()
    private let label = UILabel()
    private var currentTrack: SubtitleTrack?
    private var downloadTask: URLSessionDataTask?
    private var subtitles: Subtitles?
    private var lastUpdateTime: TimeInterval?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    deinit {
        downloadTask?.cancel()
    }

    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = false

        container.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        container.layer.cornerRadius = 4
        container.isHidden = true

        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping

        addSubview(container)
        container.addSubview(label)

        container.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),

            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 3),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -3),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -6)
        ])
    }

    func setTrack(_ track: SubtitleTrack?) {
        if let currentTrack, let track, currentTrack.url == track.url {
            return
        }

        downloadTask?.cancel()
        downloadTask = nil
        subtitles = nil
        currentTrack = track

        hideSubtitle()
        guard let track else { return }

        guard let url = URL(string: track.url) else { return }

        downloadTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                guard self.currentTrack?.url == track.url else { return }

                guard error == nil,let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    self.handleLoadFailure()
                    return
                }

                guard let data, let content = String(data: data, encoding: .utf8) else {
                    self.handleLoadFailure()
                    return
                }

                self.parseSubtitles(content)
            }
        }
        downloadTask?.resume()
    }

    private func parseSubtitles(_ content: String) {
        defer { downloadTask = nil }

        do {
            subtitles = try Subtitles(content: content, expectedExtension: "vtt")
            if let lastUpdateTime {
                updateSubtitle(at: lastUpdateTime)
            }
        } catch {
            handleLoadFailure()
        }
    }

    func updateSubtitle(at time: TimeInterval) {
        lastUpdateTime = time

        guard let subtitles else { return }

        if let cue = subtitles.firstCue(containing: time) {
            label.text = cue.text
            container.isHidden = false
        } else {
            hideSubtitle()
        }
    }

    private func hideSubtitle() {
        label.text = nil
        container.isHidden = true
    }

    private func handleLoadFailure() {
        hideSubtitle()
        downloadTask = nil
    }
}
