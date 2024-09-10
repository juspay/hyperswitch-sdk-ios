import HyperswitchScancard

@objc(HyperswitchScancard)
class HyperswitchScancard: NSObject {
    
    @objc
    func launchScanCard(_ rnMessage: String, _ rnCallback: @escaping RCTResponseSenderBlock) {
        
        DispatchQueue.main.async {
            var message: [String:Any] = [:]
            var callback: [String:Any] = [:]
            let cardScanSheet = CardScanSheet()
            cardScanSheet.present(from: RCTPresentedViewController()!) { result in
                
                switch result {
                case .completed(var card as ScannedCard?):
                    message["pan"] = card?.pan
                    message["expiryMonth"] =  card?.expiryMonth
                    message["expiryYear"] =  card?.expiryYear
                    callback["status"] = "Succeeded"
                    callback["data"] = message
                case .canceled:
                    callback["status"] = "Cancelled"
                case .failed(let error):
                    callback["status"] = "Failed"
                    
                }
                rnCallback([callback])
            }
        }
    }
}

