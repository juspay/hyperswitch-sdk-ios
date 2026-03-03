//
//  AuthenticationViewController.swift
//  Hyperswitch
//
//  Created by Shivam nan on 10/09/25.
//

import UIKit

class AuthenticationViewController: UIViewController {
    
    // ViewModel for API calls
    private var viewModel = AuthenticationViewModel()
    
    // 3DS Authentication Session properties
    private var authSession: AuthenticationSession?
    private var threeDSSession: ThreeDSSession?
    private var authTransaction: Transaction?
    private var aReqParams: AuthenticationRequestParameters?
    private var challengeInProgress = false
    
    // MARK: - UI Elements
    
    // 3DS Demo buttons
    private var initSessionButton = UIButton()
    private var createTransactionButton = UIButton()
    private var getAuthParamsButton = UIButton()
    private var doChallengeButton = UIButton()
    private var resetSessionButton = UIButton()
    
    
    // Status Label
    private var statusLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        setupUI()
        
        viewModel.prepareAuthentication()
    }
    
    private func setupUI() {
        
        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = "3DS Authentication Demo"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        
        // Status Label
        statusLabel.text = "Ready to test 3DS SDK"
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = .systemFont(ofSize: 16)
        view.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40).isActive = true
        statusLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        
        // Setup 3DS Buttons
        setupThreeDSButtons()
    }
    
    private func setupThreeDSButtons() {
        let buttonWidth: CGFloat = 280
        let buttonSpacing: CGFloat = 15
        
        // Initialize 3DS Session Button
        initSessionButton.setTitle("Initialize 3DS Session", for: .normal)
        initSessionButton.setTitleColor(.white, for: .normal)
        initSessionButton.backgroundColor = .systemBlue
        initSessionButton.layer.cornerRadius = 8
        initSessionButton.addTarget(self, action: #selector(initializeThreeDSSession(_:)), for: .touchUpInside)
        view.addSubview(initSessionButton)
        initSessionButton.translatesAutoresizingMaskIntoConstraints = false
        initSessionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        initSessionButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        initSessionButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        initSessionButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40).isActive = true
        
        // Create Transaction Button
        createTransactionButton.setTitle("Create Transaction", for: .normal)
        createTransactionButton.setTitleColor(.white, for: .normal)
        createTransactionButton.backgroundColor = .systemBlue
        createTransactionButton.layer.cornerRadius = 8
        createTransactionButton.addTarget(self, action: #selector(createTransaction(_:)), for: .touchUpInside)
        view.addSubview(createTransactionButton)
        createTransactionButton.translatesAutoresizingMaskIntoConstraints = false
        createTransactionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        createTransactionButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        createTransactionButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        createTransactionButton.topAnchor.constraint(equalTo: initSessionButton.bottomAnchor, constant: buttonSpacing).isActive = true
        
        // Get Auth Request Parameters Button
        getAuthParamsButton.setTitle("Get Auth Request Parameters", for: .normal)
        getAuthParamsButton.setTitleColor(.white, for: .normal)
        getAuthParamsButton.backgroundColor = .systemBlue
        getAuthParamsButton.layer.cornerRadius = 8
        getAuthParamsButton.addTarget(self, action: #selector(getAuthenticationRequestParameters(_:)), for: .touchUpInside)
        view.addSubview(getAuthParamsButton)
        getAuthParamsButton.translatesAutoresizingMaskIntoConstraints = false
        getAuthParamsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        getAuthParamsButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        getAuthParamsButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        getAuthParamsButton.topAnchor.constraint(equalTo: createTransactionButton.bottomAnchor, constant: buttonSpacing).isActive = true
        
        // Do Challenge Button
        doChallengeButton.setTitle("Do Challenge", for: .normal)
        doChallengeButton.setTitleColor(.white, for: .normal)
        doChallengeButton.backgroundColor = .systemBlue
        doChallengeButton.layer.cornerRadius = 8
        doChallengeButton.addTarget(self, action: #selector(doChallenge(_:)), for: .touchUpInside)
        view.addSubview(doChallengeButton)
        doChallengeButton.translatesAutoresizingMaskIntoConstraints = false
        doChallengeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        doChallengeButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        doChallengeButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        doChallengeButton.topAnchor.constraint(equalTo: getAuthParamsButton.bottomAnchor, constant: buttonSpacing).isActive = true
        
        // Reset Session Button
        resetSessionButton.setTitle("Reset", for: .normal)
        resetSessionButton.setTitleColor(.white, for: .normal)
        resetSessionButton.backgroundColor = .systemBlue
        resetSessionButton.layer.cornerRadius = 8
        resetSessionButton.addTarget(self, action: #selector(resetSession(_:)), for: .touchUpInside)
        view.addSubview(resetSessionButton)
        resetSessionButton.translatesAutoresizingMaskIntoConstraints = false
        resetSessionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        resetSessionButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        resetSessionButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        resetSessionButton.topAnchor.constraint(equalTo: doChallengeButton.bottomAnchor, constant: buttonSpacing).isActive = true
        
        // Initialize button states
        updateButtonStates()
    }
    
    @objc
    private func dismissViewController() {
        dismiss(animated: true)
    }
    
    // MARK: - 3DS Authentication Demo Functions
    
    @objc
    func initializeThreeDSSession(_ sender: Any) {
        statusLabel.text = "Step 1: Creating authentication session..."
        
        // Step 1: Create authentication session via API
        viewModel.createAuthSession { [weak self] authId, error in
            guard let self = self else { return }
            
            if let error = error {
                self.statusLabel.text = "-- Failed to create authentication session:\n\(error.localizedDescription)"
                self.updateButtonStates()
                return
            }
            
            guard let authId = authId else {
                self.statusLabel.text = "-- Failed to create authentication session: No auth ID returned"
                self.updateButtonStates()
                return
            }
            
            self.statusLabel.text = "-- Authentication session created!\nAuth ID: \(authId)\n\nStep 2: Checking eligibility..."
            
            // Step 2: Check eligibility
            self.viewModel.checkEligibility { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    self.statusLabel.text = "-- Eligibility check failed:\n\(error.localizedDescription)"
                    self.updateButtonStates()
                    return
                }
                
                self.statusLabel.text = "-- Eligibility check passed!\n\nNow initializing 3DS SDK session..."
                self.initializeSDKSession()
            }
        }
    }
    
    private func initializeSDKSession() {
        guard let publishableKey = viewModel.publishableKey else {
            statusLabel.text = "-- No publishable key available. Please wait for authentication preparation."
            return
        }
        
        authSession = AuthenticationSession(
            publishableKey: publishableKey
        )
        
        Task {
            do {
                let configuration = AuthenticationConfiguration(
                    preferredProvider: .trident
                )
                
                self.threeDSSession = try await authSession?.initThreeDSSession(
                    authIntentClientSecret: viewModel.clientSecret ?? "",
                    configuration: configuration
                )
                
                await MainActor.run {
                    statusLabel.text = "-- 3DS SDK Session initialized successfully!\nReady to create transaction."
                    updateButtonStates()
                }
            } catch {
                await MainActor.run {
                    statusLabel.text = "-- Failed to initialize 3DS SDK session:\n\(error.localizedDescription)"
                    authSession = nil
                    updateButtonStates()
                }
            }
        }
    }
    
    @objc
    func createTransaction(_ sender: Any) {
        guard let threeDSSession = threeDSSession else {
            statusLabel.text = "-- No active session. Please initialize first."
            return
        }
        
        statusLabel.text = "-- Creating transaction..."
        
        Task {
            do {
                let transaction = try await threeDSSession.createTransaction(
                    messageVersion: "2.2.0",
                    directoryServerId: "A000000004",
                    cardNetwork: "VISA"
                )
                
                await MainActor.run {
                    authTransaction = transaction
                    statusLabel.text = "-- Transaction created successfully!\nReady for authentication flow."
                    updateButtonStates()
                }
            } catch {
                await MainActor.run {
                    statusLabel.text = "-- Failed to create transaction:\n\(error.localizedDescription)"
                    updateButtonStates()
                }
            }
        }
    }
    
    @objc
    func getAuthenticationRequestParameters(_ sender: Any) {
        guard let transaction = authTransaction else {
            statusLabel.text = "-- No active transaction. Please create transaction first."
            return
        }
        
        statusLabel.text = "Getting authentication request parameters..."
        
        Task {
            do {
                let aReqParams = try await transaction.getAuthenticationRequestParameters()
                
                await MainActor.run {
                    self.aReqParams = aReqParams
                    
                    statusLabel.text = """
                    -- Authentication Request Parameters Retrieved:
                    
                    SDK Encrypted data: \(String(describing: aReqParams.sdkEncryptedData?.prefix(10)))...
                    SDK Transaction ID: \(String(describing: aReqParams.sdkTransactionID))
                    Message Version: \(String(describing: aReqParams.messageVersion))
                    SDK App ID: \(String(describing: aReqParams.sdkAppID))
                    SDK Reference Number: \(String(describing: aReqParams.sdkReferenceNumber?.prefix(10)))...
                    Device Data: \(String(describing: aReqParams.deviceData?.prefix(6)))...
                    SDK Ephemeral Public Key: \(String(describing: aReqParams.sdkEphemeralPublicKey).prefix(6))...
                    
                    """
                }
            } catch {
                await MainActor.run {
                    statusLabel.text = "-- Failed to get authentication parameters:\n\(error.localizedDescription)"
                }
            }
        }
    }
    
    @objc
    func doChallenge(_ sender: Any) {
        guard let transaction = authTransaction,
              let aReqParams = self.aReqParams else {
            statusLabel.text = "-- No active transaction. Please create transaction first."
            return
        }
        
        challengeInProgress = true
        statusLabel.text = "Fetching challenge parameters..."
        updateButtonStates()
        
        do {
            let progressView = try transaction.getProgressView()
            progressView.start()
            
            // Fetch challenge parameters from the server
            viewModel.fetchChallengeParams(aReqParams) { [weak self] challengeParams, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.statusLabel.text = "-- Failed to fetch challenge params:\n\(error.localizedDescription)"
                    self.challengeInProgress = false
                    self.updateButtonStates()
                    progressView.stop()
                    return
                }
                
                guard let challengeParameters = challengeParams else {
                    self.statusLabel.text = "-- No challenge parameters received"
                    self.challengeInProgress = false
                    self.updateButtonStates()
                    progressView.stop()
                    return
                }
                
                self.statusLabel.text = "Challenge parameters fetched! Starting challenge flow..."
                
                // Create challenge status receiver
                let challengeStatusReceiver = DemoChallengeStatusReceiver(transaction: transaction) { [weak self] result in
                    DispatchQueue.main.async {
                        progressView.stop()
                        self?.challengeInProgress = false
                        self?.statusLabel.text = result
                        self?.updateButtonStates()
                    }
                }
                
                DispatchQueue.main.async {
                    do {
                        // Start the challenge
                        try transaction.doChallenge(
                            viewController: self,
                            challengeParameters: challengeParameters,
                            challengeStatusReceiver: challengeStatusReceiver,
                            timeOut: 5
                        )
                        
                        self.statusLabel.text = "-- Challenge flow started successfully!\nWaiting for challenge completion..."
                        
                    } catch {
                        progressView.stop()
                        self.statusLabel.text = "-- Failed to start challenge:\n\(error.localizedDescription)"
                        self.challengeInProgress = false
                        self.updateButtonStates()
                    }
                }
            }
        } catch {
            statusLabel.text = "-- Failed to get authentication parameters:\n\(error.localizedDescription)"
            challengeInProgress = false
            updateButtonStates()
        }
    }
    
    @objc
    func resetSession(_ sender: Any) {
        viewModel = AuthenticationViewModel()
        
        // Reset local state
        authSession = nil
        authTransaction = nil
        challengeInProgress = false
        statusLabel.text = "Session reset. Preparing authentication..."
        updateButtonStates()
        
        // Refresh pk and cs
        viewModel.prepareAuthentication()
    }
    
    private func updateButtonStates() {
        initSessionButton.isEnabled = authSession == nil
        createTransactionButton.isEnabled = authSession != nil
        getAuthParamsButton.isEnabled = authTransaction != nil
        doChallengeButton.isEnabled = authTransaction != nil && !challengeInProgress
        resetSessionButton.isEnabled = true
        
        initSessionButton.alpha = initSessionButton.isEnabled ? 1.0 : 0.5
        createTransactionButton.alpha = createTransactionButton.isEnabled ? 1.0 : 0.5
        getAuthParamsButton.alpha = getAuthParamsButton.isEnabled ? 1.0 : 0.5
        doChallengeButton.alpha = doChallengeButton.isEnabled ? 1.0 : 0.5
        resetSessionButton.alpha = 1.0
    }
}

// MARK: - Demo ChallengeStatusReceiver Implementation

class DemoChallengeStatusReceiver: ChallengeStatusReceiver {
    private let completion: (String) -> Void
    private let transaction: Transaction
    
    init(transaction: Transaction, completion: @escaping (String) -> Void) {
        self.completion = completion
        self.transaction = transaction
    }
    
    func completed(_ completionEvent: CompletionEvent) {
        completion("-- Challenge completed successfully!")
        transaction.close()
    }
    
    func cancelled() {
        completion("-- Challenge was cancelled by user")
        transaction.close()
    }
    
    func timedout() {
        completion("-- Challenge timed out")
        transaction.close()
    }
    
    func protocolError(_ protocolErrorEvent: ProtocolErrorEvent) {
        completion("-- Protocol error occurred:\n\(protocolErrorEvent.getErrorMessage())")
        transaction.close()
    }
    
    func runtimeError(_ runtimeErrorEvent: RuntimeErrorEvent) {
        let errorCode = runtimeErrorEvent.getErrorCode() ?? "Unknown"
        completion("-- Runtime error occurred:\nCode: \(errorCode)\nMessage: \(runtimeErrorEvent.getErrorMessage())")
        transaction.close()
    }
}
