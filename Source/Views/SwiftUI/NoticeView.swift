//
//  NoticeView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 13/06/24.
//

import SwiftUI

@available(iOS 14.0.0, *)
struct NoticeView: View {
    var message: String
    
    var body: some View {
        Text(message)
            .multilineTextAlignment(.center)
            .padding(8)
            .background(Color.black.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}
