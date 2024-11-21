//
//  M3U8Util.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 20/11/24.
//

import Foundation
import M3U8Parser

public class M3U8ParseUtil {
    
    static func extractContentIDFromMasterURL(masterURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            // Create a playlist model from the master URL
            let masterPlaylist = try M3U8PlaylistModel(url: masterURL)
            
            // Check if the master playlist contains a valid stream list
            if let streamList = masterPlaylist.masterPlaylist?.xStreamList, streamList.count != 0 {
                // Take the first variant's URL from the stream list
                if let variant = streamList.xStreamInf(at: 0),
                   let variantURL = variant.m3u8URL() {
                    parseVariantURL(variantURL) { result in
                        switch result {
                        case .success(let contentID):
                            completion(.success(contentID)) // Pass the contentID back
                        case .failure(let error):
                            completion(.failure(error)) // Pass the error back
                        }
                    }
                } else {
                    completion(.failure(NSError(domain: "M3U8Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No variant URL found."])))
                }
            } else {
                completion(.failure(NSError(domain: "M3U8Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No variants found in master playlist."])))
            }
        } catch {
            completion(.failure(error)) // Pass the error back if something went wrong
        }
    }
    
    static func parseVariantURL(_ variantURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            // Parse the variant playlist
            let variantPlaylist = try M3U8PlaylistModel(url: variantURL)
            
            // Access the segment list
            guard let segmentList = variantPlaylist.mainMediaPl?.segmentList, segmentList.count != 0 else {
                completion(.failure(NSError(domain: "M3U8Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No segments found in variant playlist."])))
                return
            }
            
            // Iterate through the segments and skip #EXT-X-DISCONTINUITY
            var hasDiscontinuity = false
            for index in 0..<segmentList.count {
                if let segment = segmentList.segmentInfo(at: index) {
                    // Check if the previous segment had a discontinuity
                    if hasDiscontinuity {
                        hasDiscontinuity = false // Reset the flag for the next segment
                        continue
                    }
                    
                    // Check for the #EXT-X-DISCONTINUITY tag in the raw lines
                    if let rawLines = variantPlaylist.mainMediaPl?.originalText {
                        let lines = rawLines.components(separatedBy: .newlines)
                        let currentSegmentURI = segment.mediaURL()?.absoluteString ?? ""
                        if let segmentIndex = lines.firstIndex(where: { $0.contains(currentSegmentURI) }),
                           segmentIndex > 0,
                           lines[segmentIndex - 1] == "#EXT-X-DISCONTINUITY" {
                            hasDiscontinuity = true
                            continue
                        }
                    }
                    
                    // Retrieve the key URI and extract the Content ID
                    if let key = segment.xKey,
                       let uri = key.url(),
                       let contentID = extractIDFromURI(uri: uri) {
                        completion(.success(contentID)) // Pass the Content ID back
                        return
                    }
                }
            }
            
            // If no valid contentID is found
            completion(.failure(NSError(domain: "M3U8Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No content ID found in the variant playlist."])))
        } catch {
            completion(.failure(error)) // Pass the error back
        }
    }
    
    // Helper function to extract contentID from URI
    static func extractIDFromURI(uri: String) -> String? {
        if uri.hasPrefix("skd://") {
            return uri // Retain the full URI with skd:// prefix
        }
        return nil
    }
}
