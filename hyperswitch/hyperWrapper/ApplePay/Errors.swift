enum ErrorType {
    static let Failed = "Failed"
    static let Canceled = "Canceled"
    static let Unknown = "Unknown"
    static let Timeout = "Timeout"
}

class Errors {
    static internal let isPIClientSecretValidRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: "^pi_[^_]+_secret_[^_]+$", options: [])

    static internal let isSetiClientSecretValidRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: "^seti_[^_]+_secret_[^_]+$", options: [])
    
    static internal let isEKClientSecretValidRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: "^ek_[^_](.)+$", options: [])

    class func isPIClientSecretValid(clientSecret: String) -> Bool {
        return (Errors.isPIClientSecretValidRegex?.numberOfMatches(
            in: clientSecret,
            options: .anchored,
            range: NSRange(location: 0, length: clientSecret.count))) == 1
    }
    class func isSetiClientSecretValid(clientSecret: String) -> Bool {
        return (Errors.isSetiClientSecretValidRegex?.numberOfMatches(
            in: clientSecret,
            options: .anchored,
            range: NSRange(location: 0, length: clientSecret.count))) == 1
    }
    class func isEKClientSecretValid(clientSecret: String) -> Bool {
        return (Errors.isEKClientSecretValidRegex?.numberOfMatches(
            in: clientSecret,
            options: .anchored,
            range: NSRange(location: 0, length: clientSecret.count))) == 1
    }

    class func createError (_ code: String, _ message: String?) -> NSDictionary {
        let value: NSDictionary = [
            "code": code,
            "message": message ?? NSNull(),
            "localizedMessage": message ?? NSNull(),
            "declineCode": NSNull(),
            "stripeErrorCode": NSNull(),
            "type": NSNull()
        ]
        
        return ["error": value]
    }
    
    class func getRootError(_ error: NSError?) -> NSError? {
        // Dig and find the underlying error, otherwise we'll throw errors like "Try again"
        if let underlyingError = error?.userInfo[NSUnderlyingErrorKey] as? NSError {
            return getRootError(underlyingError)
        }
        return error
    }
    
    static let MISSING_INIT_ERROR = Errors.createError(ErrorType.Failed, "Hyperswitch has not been initialized. Initialize Hyperswitch in your app with the HyperProvider component or the initHyper method.")
}

