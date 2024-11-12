//
//  M3U8ParseUtil.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 12/11/24.
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
            // Parse the variant playlist to retrieve the media playlist model
            let variantPlaylist = try M3U8PlaylistModel(url: variantURL)
            
            // Access the first segment from the variant playlist (segmentList is a list of M3U8SegmentInfo)
            if let segmentList = variantPlaylist.mainMediaPl?.segmentList, segmentList.count != 0 {
                if let key = segmentList.segmentInfo(at: 0)?.xKey,
                   let uri = key.url(),
                   let contentID = extractIDFromURI(uri: uri) {
                    completion(.success(contentID)) // Pass the extracted contentID back
                } else {
                    completion(.failure(NSError(domain: "M3U8Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No contentID found in the variant."])))
                }
            } else {
                completion(.failure(NSError(domain: "M3U8Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No segments found in variant playlist."])))
            }
        } catch {
            completion(.failure(error)) // Pass the error back if something went wrong
        }
    }

    // Helper function to extract contentID from URI
    static func extractIDFromURI(uri: String) -> String? {
        if uri.contains("skd://") {
            return uri.replacingOccurrences(of: "skd://", with: "")
        }
        return nil
    }
}
