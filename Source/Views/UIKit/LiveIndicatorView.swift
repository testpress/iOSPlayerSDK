//
//  LiveIndicatorView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 18/06/24.
//

import Foundation
import UIKit

class LiveIndicatorView: UIView {
    var isBehindLiveEdge: Bool = true {
        didSet{
            dotView.backgroundColor = isBehindLiveEdge ? .lightGray : .red
        }
    }
    
    private lazy var dotView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .red
        view.layer.cornerRadius = 6
        return view
    }()
    
    private lazy var liveLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "LIVE"
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        label.isUserInteractionEnabled = true
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        guard let superview = self.superview else { return }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dotView.centerYAnchor.constraint(equalTo: superview.centerYAnchor),
            dotView.widthAnchor.constraint(equalToConstant: 10),
            dotView.heightAnchor.constraint(equalToConstant: 10)
        ])
        
        NSLayoutConstraint.activate([
            liveLabel.leadingAnchor.constraint(equalTo: dotView.trailingAnchor, constant: 4),
            liveLabel.centerYAnchor.constraint(equalTo: superview.centerYAnchor),
        ])
    }
        
    private func setupView() {
        addSubview(dotView)
        addSubview(liveLabel)
    }    
}
