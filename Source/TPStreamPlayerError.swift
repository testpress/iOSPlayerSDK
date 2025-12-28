import Foundation
public enum TPStreamPlayerError: Error {
    case resourceNotFound
    case unauthorizedAccess
    case failedToFetchLicenseKey
    case noInternetConnection
    case serverError
    case networkTimeout
    case incompleteOfflineVideo
    case unknownError
    case drmSimulatorError
    
    public var code: Int {
        switch self {
        case .resourceNotFound: return 5001
        case .unauthorizedAccess: return 5002
        case .failedToFetchLicenseKey: return 5003
        case .noInternetConnection: return 5004
        case .serverError: return 5005
        case .networkTimeout: return 5006
        case .incompleteOfflineVideo: return 5007
        case .drmSimulatorError: return 5008
        case .unknownError: return 5100
        }
    }
    
    public var message: String {
        switch self {
        case .resourceNotFound:
            return "The video is not available. Please try another one."
        case .unauthorizedAccess:
            return "Sorry, you don't have permission to access this video. Please check your credentials and try again."
        case .failedToFetchLicenseKey:
            return "There was an issue fetching the license key for this video. Please try again later."
        case .noInternetConnection:
            return "Oops! It seems like you're not connected to the internet. Please check your connection and try again."
        case .serverError:
            return "We're sorry, but there's an issue on our server. Please try again later."
        case .networkTimeout:
            return "The request took too long to process due to a slow or unstable network connection. Please try again."
        case .incompleteOfflineVideo:
            return "This video hasn't been downloaded completely. Please try downloading it again."
        case .drmSimulatorError:
            return "DRM protected content cannot be played in simulator. Please use a physical device."
        case .unknownError:
            return "Oops! Something went wrong. Please contact support for assistance and provide details about the issue."
        }
    }
}

extension TPStreamPlayerError: CustomNSError {    
    public var errorCode: Int {
        return self.code
    }
    
    public var errorUserInfo: [String : Any] {
        return [NSDebugDescriptionErrorKey: self.message]
    }
}
