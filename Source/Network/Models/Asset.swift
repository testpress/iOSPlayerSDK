//
//  VideoDetail.swift
//  TPStreamsSDK
//
//  Created by Testpress on 03/06/23.
//

import Foundation

struct Asset {
    let id: String
    let title: String
    let video: Video
    
    struct Video{
        let playbackURL: String
        let status: String
    }
}
