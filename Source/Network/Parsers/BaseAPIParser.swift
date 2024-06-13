//
//  BaseAPIParser.swift
//  TPStreamsSDK
//
//  Created by Testpress on 13/06/24.
//

import Foundation

protocol APIParser {
    func parseAsset(data: Data) throws -> Asset
    func parseVideo(from dictionary: [String: Any]?) -> Video?
    func parseLiveStream(from dictionary: [String: Any]?) -> LiveStream?
}
