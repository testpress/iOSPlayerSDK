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
        reset()
    }

    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = false

        createContainer()
        createLabel()

        addSubview(container)
        container.addSubview(label)

        setupConstraints()
    }

    private func createContainer() {
        container.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        container.layer.cornerRadius = 4
        container.isHidden = true
        container.translatesAutoresizingMaskIntoConstraints = false
    }

    private func createLabel() {
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupConstraints() {
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

        reset()
        currentTrack = track

        hideSubtitle()
        guard let track else { return }

        guard let url = URL(string: track.url) else { return }

        loadSubtitles(from: url, for: track)
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

    private func loadSubtitles(from url: URL, for track: SubtitleTrack) {
        downloadTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                guard self.currentTrack?.url == track.url else { return }
                guard error == nil,
                      let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let data,
                      let content = String(data: data, encoding: .utf8) else {
                    self.handleLoadFailure()
                    return
                }
                self.onDownloadSuccess(content)
            }
        }
        downloadTask?.resume()
    }

    private func onDownloadSuccess(_ content: String) {
        parseSubtitles(content)
        if let lastUpdateTime {
            updateSubtitle(at: lastUpdateTime)
        }
    }

    private func parseSubtitles(_ content: String) {
        defer { downloadTask = nil }

        do {
            subtitles = try Subtitles(content: content, expectedExtension: "vtt")
        } catch {
            handleLoadFailure()
        }
    }

    private func reset() {
        downloadTask?.cancel()
        downloadTask = nil
        subtitles = nil
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
