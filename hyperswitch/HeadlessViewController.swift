//
//  HeadlessViewController.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 02/07/24.
//

import SwiftUI
import UIKit
import Combine

class HeadlessViewController: UIViewController {
    
    @ObservedObject var hyperViewModel = HyperViewModel()
    
    private let statusLabel = UILabel()
    private let stackView = UIStackView()
    private let scrollView = UIScrollView()
    
    private let headlessbutton = UIButton()
    private let getDefault = UIButton()
    private let getLast = UIButton()
    private let getData = UIButton()
    private let confirmDefault = UIButton()
    private let confirmLast = UIButton()
    private let confirm = UIButton()
    private let reloadButton = UIButton()
    private let init3dsButton = UIButton()
    private let generateAReqParamsButton = UIButton()
    private let receiveChallengeParamsButton = UIButton()
    private let doChallengeButton = UIButton()
    
    private var headlessbuttonConfig = UIButton.Configuration.filled()
    private var getDefaultConfig = UIButton.Configuration.filled()
    private var getLastConfig = UIButton.Configuration.filled()
    private var getDataConfig = UIButton.Configuration.filled()
    private var confirmDefaultConfig = UIButton.Configuration.filled()
    private var confirmLastConfig = UIButton.Configuration.filled()
    private var confirmConfig = UIButton.Configuration.filled()
    private var reloadButtonConfiguration = UIButton.Configuration.plain()
    private var init3dsButtonConfig = UIButton.Configuration.filled()
    private var generateAReqParamsButtonConfig = UIButton.Configuration.filled()
    private var receiveChallengeParamsButtonConfig = UIButton.Configuration.filled()
    private var doChallengeButtonConfig = UIButton.Configuration.filled()
    
    private var handler: PaymentSessionHandler?
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 0.2)
        viewFrame()
        hyperViewModel.preparePaymentSheet()
        asyncBind()
    }
    
    private func asyncBind() {
        hyperViewModel.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .loading:
                    self?.statusLabel.text = "Loading..."
                case .success:
                    self?.statusLabel.text = "Connected to Server"
                case .failure(let message):
                    self?.statusLabel.text = message
                }
            }
            .store(in: &cancellables)
    }
    
    @objc
    func reload(_ sender: Any) {
        hyperViewModel.preparePaymentSheet()
        self.reloadButton.isUserInteractionEnabled = false
        UIView.animate(withDuration: 1.6, animations: {
            self.reloadButton.backgroundColor = .white
        }) { (_) in
            self.reloadButton.backgroundColor = .systemBlue
            self.reloadButton.isUserInteractionEnabled = true
        }
    }
    
    
    func initSavedPaymentMethodSessionCallback(handler: PaymentSessionHandler)-> Void {
        self.handler = handler
    }
    
    
    @objc func launchHeadless(_ sender: Any) {
        hyperViewModel.paymentSession?.getCustomerSavedPaymentMethods(initSavedPaymentMethodSessionCallback)
        getDefault.isEnabled = true
        getLast.isEnabled = true
        getData.isEnabled = true

    }
    
    @objc func getCustomerDefaultSavedPaymentMethodData(_ sender: Any) {
        let paymentMethod = self.handler?.getCustomerDefaultSavedPaymentMethodData()
        switch paymentMethod {
        case let card as Card:
            print(["type": "card", "message": card.toHashMap()])
            self.statusLabel.text = "card → \(card.toHashMap())"
            confirmDefault.isEnabled = true
        case let wallet as Wallet:
            print(["type": "wallet", "message": wallet.toHashMap()])
            self.statusLabel.text = "wallet → \(wallet.toHashMap())"
            confirmDefault.isEnabled = true
        case let error as PMError:
            print(["type": "error", "message": error.toHashMap()])
            self.statusLabel.text = "error → \(error.toHashMap())"
        default:
            print(["type": "error", "message": ["code": "0", "message": "No Payment Method Available"]])
            self.statusLabel.text = "error → No Payment Method Available"
        }
    }
    
    @objc func getCustomerLastUsedPaymentMethodData(_ sender: Any) {
        let paymentMethod = self.handler?.getCustomerLastUsedPaymentMethodData()
        switch paymentMethod {
        case let card as Card:
            print(["type": "card", "message": card.toHashMap()])
            self.statusLabel.text = "card → \(card.toHashMap())"
            confirmLast.isEnabled = true
        case let wallet as Wallet:
            print(["type": "wallet", "message": wallet.toHashMap()])
            self.statusLabel.text = "wallet → \(wallet.toHashMap())"
            confirmLast.isEnabled = true
        case let error as PMError:
            print(["type": "error", "message": error.toHashMap()])
            self.statusLabel.text = "error → \(error.toHashMap())"
        default:
            print(["type": "error", "message": ["code": "0", "message": "No Payment Method Available"]])
            self.statusLabel.text = "error → No Payment Method Available"
        }
    }
    
    @objc func getCustomerSavedPaymentMethodData(_ sender: Any) {
        let paymentMethod = self.handler?.getCustomerSavedPaymentMethodData()
        
        guard let pm = paymentMethod else{
            print(["type": "error", "message": ["code": "0", "message": "No Payment Method Available"]])
            self.statusLabel.text = "error → No Payment Method Available"
            return
        }
        for paymentMethods in pm{
            switch paymentMethods {
            case let card as Card:
                print(["type": "card", "message": card.toHashMap()])
                self.statusLabel.text = "card → \(card.toHashMap())"
                confirm.isEnabled = true
            case let wallet as Wallet:
                print(["type": "wallet", "message": wallet.toHashMap()])
                self.statusLabel.text = "wallet → \(wallet.toHashMap())"
                confirm.isEnabled = true
            case let error as PMError:
                print(["type": "error", "message": error.toHashMap()])
                self.statusLabel.text = "error → \(error.toHashMap())"
            default:
                print(["type": "error", "message": ["code": "0", "message": "No Payment Method Available"]])
                self.statusLabel.text = "error → No Payment Method Available"
            }
        }
    }
    
    @objc func confirmWithCustomerDefaultPaymentMethod(_ sender: Any) {
        handler?.confirmWithCustomerDefaultPaymentMethod(resultHandler: resultHandler)
    }
    
    @objc func confirmWithCustomerLastUsedPaymentMethod(_ sender: Any) {
        handler?.confirmWithCustomerLastUsedPaymentMethod(resultHandler: resultHandler)
    }
    
    @objc func confirmWithCustomerPaymentToken(_ sender: Any) {
//        handler?.confirmWithCustomerPaymentToken(<#T##String#>, <#T##String?#>, <#T##(PaymentResult) -> Void#>)
    }
    
    @objc func initializeThreeDs(_ sender: Any) {
        // Call the HyperHeadless module to emit the init3ds event
        HyperHeadless.shared?.emitInit3DsEvent(
            threeDsSdkApiKey: "test_api_key_123", 
            environment: "sandbox"
        )
        self.statusLabel.text = "3DS Initialization Event Emitted"
        print("3DS Initialization Event Emitted with API Key: test_api_key_123, Environment: sandbox")
    }
    
    @objc func generateAReqParams(_ sender: Any) {
        // Call the HyperHeadless module to emit the generateAReqParams event
        HyperHeadless.shared?.emitGenerateAReqParamsEvent(
            messageVersion: "2.3.1",
            directoryServerId: "A000000004", 
            cardNetwork: "VISA"
        )
        self.statusLabel.text = "Generate AReq Params Event Emitted"
        print("Generate AReq Params Event Emitted with MessageVersion: 2.1.0, DirectoryServerId: A0100020, CardNetwork: VISA")
    }
    
    @objc func receiveChallengeParams(_ sender: Any) {
        // Call the HyperHeadless module to emit the receiveChallengeParams event
        HyperHeadless.shared?.emitReceiveChallengeParamsEvent(
            acsSignedContent: "eyJhbGciOiJQUzI1NiIsIng1YyI6WyJNSUlFRURDQ0F2aWdBd0lCQWdJSWFYL2RWZE9CM0hnd0RRWUpLb1pJaHZjTkFRRUxCUUF3ZERFTE1Ba0dBMVVFQmhNQ1EwZ3hDekFKQmdOVkJBZ1RBbHBJTVE4d0RRWURWUVFIRXdaYWRYSnBZMmd4RlRBVEJnTlZCQW9UREU1bGRHTmxkR1Z5WVNCQlJ6RWJNQmtHQTFVRUN4TVNRV054ZFdseWFXNW5JRkJ5YjJSMVkzUnpNUk13RVFZRFZRUURFd296WkhOemNISmxka05CTUI0WERUSTBNVEV4TVRFMU1EZ3dNRm9YRFRNek1URXhNVEUxTURnd01Gb3dnWk14Q3pBSkJnTlZCQVlUQWtOSU1ROHdEUVlEVlFRSURBWmFkWEpwWTJneEN6QUpCZ05WQkFjTUFscElNUlV3RXdZRFZRUUtEQXhPWlhSalpYUmxjbUVnUVVjeElEQWVCZ05WQkFzTUYxTmxZM1Z5WlNCRWFXZHBkR0ZzSUZCaGVXMWxiblJ6TVMwd0t3WURWUVFERENSall6WmhOelUwWWkwMU9EQTNMVFF6TkRNdFlUbGxNQzA0TjJNMlpqTTNaREJqTURVd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUUMvLzdpT3RaK0ljS1E3MWtnNENxS2hmR2ZqdXVDV3N2OUh1d1c0WXgyMkFGa0RyRGpNOURsZmJkaVo2VEpyNFFjaU9hcm95QkJONTRTT25LclE2MjRJbytpdCtXRWZ0cFhKNDg1V2xydUF3TUdFU1lrTmtnRmdNOEtFbEdIOU54UlJUR2MxQnd0WHdTdjZwbnE4TTRXc0s4SXpVWlZodU9RQ3ZYOEVsK3UzM2RrSEsrbnFLTGpENEZtUlZBeHdKTFJTcWJBeitUMlJmQWJtOHVWUVQvSlVLb3h5cVhGZlFOSVhCZGRLZEdyQXhYdUJUMTBsbjZtYlkwcE9GQi93enAxVnlxdlYvckNLL3dVSVpnTVNXRzN5djVUSnREV2ZHZmk0TVg4ajg3Tit0VlFia1J4d2d3bmgrWWVFaW10cm9VbEV0aUsxc04zYURWbExGK0JoME8rdkFnTUJBQUdqZ1lVd2dZSXdIZ1lKWUlaSUFZYjRRZ0VOQkJFV0QzaGpZU0JqWlhKMGFXWnBZMkYwWlRBTUJnTlZIUk1CQWY4RUFqQUFNQjBHQTFVZERnUVdCQlRRb0hrUG1qcEkydnVIYkFwVit1ekVWbXhRTWpBTEJnTlZIUThFQkFNQ0E3Z3dFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUhBd0l3RVFZSllJWklBWWI0UWdFQkJBUURBZ1dnTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFBQnB4V0piM1ZTL242MmVNeUNhOEZJNnJCY0FFOXZndkYxZ2xJczg4Vk5ENGYyUXpJODFzenBKejZlTjJWRWFnL2VyaEpLTUVoTkk2ZzllRXVMS3ZZbmVxMUFVd3BYdG1rczVhSlhVRC95d0RWS2w1eXpwMzB4WWxZamtlWVQzbVRhNkVsU3BRQ2h5UnBjbkNDVDlCRDRncXFnOVRGZ2NTb1BqcDRKbXJ0TnpsODJIV2NFRUZLbE1DMXVwbDY1M0xzZUprdFduekxlbkg5dkt2OGFyZWRDSVNibllsV05pT2ZoVEZmUmZ3dE5qMmRaNXlZSFMycnl4TVBzUTh5a3EwYllaSjlHOVd3UXJQM0w5RUtEalV6WEJjL29hR0RMY3k2akZ3TnBvaldKSVh4alBTSWRkZTNNUGx4SXY4YWQyYjBhbS9LWi9IMk1xOHhURFhUbGNrcTAiLCJNSUlEdkRDQ0FxU2dBd0lCQWdJSVh4MUhUcVhOaTljd0RRWUpLb1pJaHZjTkFRRU1CUUF3ZERFTE1Ba0dBMVVFQmhNQ1EwZ3hDekFKQmdOVkJBZ1RBbHBJTVE4d0RRWURWUVFIRXdaYWRYSnBZMmd4RlRBVEJnTlZCQW9UREU1bGRHTmxkR1Z5WVNCQlJ6RWJNQmtHQTFVRUN4TVNRV054ZFdseWFXNW5JRkJ5YjJSMVkzUnpNUk13RVFZRFZRUURFd296WkhOemNISmxka05CTUI0WERUSTBNRGd3TnpFeU1EUXdNRm9YRFRNME1EZ3dOekV5TURRd01Gb3dkREVMTUFrR0ExVUVCaE1DUTBneEN6QUpCZ05WQkFnVEFscElNUTh3RFFZRFZRUUhFd1phZFhKcFkyZ3hGVEFUQmdOVkJBb1RERTVsZEdObGRHVnlZU0JCUnpFYk1Ca0dBMVVFQ3hNU1FXTnhkV2x5YVc1bklGQnliMlIxWTNSek1STXdFUVlEVlFRREV3b3paSE56Y0hKbGRrTkJNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQTM1NTMwMG5lR0tFSkpsY1pCSDdOMEs3dCtVWC82Y2dZUkd4amx2ak9hRzdFaHV5QllyLzdodUxidGtVc2YwRVl4dWJnNWkwWlI3ZlREa1U1czZKZ1JoZmVFTlZndXNUTVB5WU5rN2lPS3NFWHdhaHY0VW11dGh2T3RZaWRWL1d3OXkrZHZjRWIxNHBsWDY4NXE5bnpOcGp4eHdnMFBBdkJJQzNhOWU2Yi82WXgvQ0UwZm5iR05wU1FETFl4QzhBL3ZCMXk4RStBaFJpR0F4Tk5CdHkva3VVdkJsRDVLZCtmc0ZqSnRVK2hJMERFV0VYVmVlR3FVME9aeWZMb2JxUFVNbk5LWVRTR2o3SG5YVWtCYkZLWE9LN0V5MURnc3hCdUFsaUlsV0x4YXRBQ245QnpzdXN2cU51U3Z5L2lxZHdOUVp2MENBcnQ0TWZsV3RNSW5kd1JHUUlEQVFBQm8xSXdVREFQQmdOVkhSTUJBZjhFQlRBREFRSC9NQjBHQTFVZERnUVdCQlRKMk9aSWpLcS9TSTM3SXNValhzYlI4cEZQN2pBTEJnTlZIUThFQkFNQ0FRWXdFUVlKWUlaSUFZYjRRZ0VCQkFRREFnQUhNQTBHQ1NxR1NJYjNEUUVCREFVQUE0SUJBUUFmZWQ5T3RWdHhQR3B6TS9KS3g4TUsrWm5XYjI0c0VGMlNXaERhNzhmZ2syRWFzbmsrT1hrTzd1R0tTdm5uTFB1UXFEbzBiZmhhS1lwQ1QvTjNTYk8vbXZ0NHdORzBwc0EySGUvYXBvWEUzdEN1eFdYaGg4SnVkTnlEQzBCaHRTVXE2WDliWVlNOFhzUnE0LzQ1ejY3bnlCYlowVHExRVdMQ1BKci82b1FxTXlNTTFvVFp3WnFETlpjMzd3TkFCelVpVnVtNGdUQW9YZTdwNDJVdVNsdXJZS3hmTzZpeExoaFNOWWtta2lhRHl2QlNwVFFJWitBc2REcUI5OFdIeDBiYUlqSmpCZU1tZSt1L1BpZmVGRjNDUUxSa28wSWxKUWdldDczZlBZNGFzWXhwekx0M1lQNE1lbmg2dTVLVHFucTJWUGd2aGZMTGp1R3libkNDLytERSJdfQ.eyJhY3NVUkwiOiJodHRwczovL25kbS1wcmV2LjNkc3Mtbm9uLXByb2QuY2xvdWQubmV0Y2V0ZXJhLmNvbS9hY3MvY2hhbGxlbmdlIiwiYWNzRXBoZW1QdWJLZXkiOnsia3R5IjoiRUMiLCJ4IjoiYXJ5Q2NsRnhKNkFDZEVLdlBGQzc5NVVOQ0NsTjA3Tnh1N2VkZGMzWFBiRSIsInkiOiJmaXhXb3JwcnZvNTlrcHFtbFNpMEw1UGlOSHJKOS1fNjNWaTdBQU01RTl3IiwiY3J2IjoiUC0yNTYifSwic2RrRXBoZW1QdWJLZXkiOnsia3R5IjoiRUMiLCJjcnYiOiJQLTI1NiIsIngiOiJYcjF0TEdBMkFWNEF2NDgzNUd6UG5pcl9Yd1dFNmhUaVl1bjRORXBadEJzIiwieSI6InFmR2J5RWhjaHliakVzSm9TNFctQmpteTdXS3VNYUVvRjVnVXhrZkd1MGcifX0.Z1l8rY3FATzQ-DN_fKS4BVhRtN9EFQ7E2g6M_3ojf_OOYJ-IXoYTye0DtxgM_DU9m_KzVZdtks_vjRuF9XwVp2GTHkdUzc7fLLkh6ninikZslBACaILsQxHsB_UqNVHpI85RQcQEdRJSf2SBYNy6lB4bJsMI7Ia_rL8EQOAeI8vDGdKx2G_HleXsAKek4sKRefLyLZzf_sjHEC3VazFbfbnDqLtUv1Pv1ADmIhmzhp9WfptB0Lg5Y0CalNCXLaJKiRAfXQJFtU8WPdGDGgYhf2N9VAwgG1ZkJoMI8L18N3-l2zWZXFK0flPb0ZRuKbVp0b4w2pyKtuvMEywMXs5fJA",
            acsTransactionId: "649c6f76-13e6-49e3-b14f-a30686b7f109",
            acsRefNumber: "3DS_LOA_ACS_201_13579",
            threeDSServerTransId: "23c13695-8efc-4875-a322-0ccb13c3a8c4",
            threeDSRequestorAppURL: ""
        )
        self.statusLabel.text = "Receive Challenge Params Event Emitted"
        print("Receive Challenge Params Event Emitted with test challenge parameters")
    }
    
    @objc func doChallenge(_ sender: Any) {
        // Call the HyperHeadless module to emit the doChallenge event
        HyperHeadless.shared?.emitDoChallengeEvent()
        self.statusLabel.text = "Do Challenge Event Emitted"
        print("Do Challenge Event Emitted")
    }
    
    func resultHandler(_ paymentResult: PaymentResult) {
        switch paymentResult {
        case .completed(let data):
            print(["type": "completed", "message": data])
            self.statusLabel.text = "completed → \(data)"
        case .canceled(let data):
            print(["type": "canceled", "message": data])
            self.statusLabel.text = "canceled → \(data)"
        case .failed(let error):
            print(["type": "failed", "message": "\(error)"])
            self.statusLabel.text = "failed → \(error)"
        }
    }
}

extension HeadlessViewController {
    func viewFrame(){   
        stackView.axis  = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalCentering
        stackView.spacing = 20.0
        stackView.addArrangedSubview(reloadButton)
        stackView.addArrangedSubview(headlessbutton)
        stackView.addArrangedSubview(getDefault)
        stackView.addArrangedSubview(getLast)
        stackView.addArrangedSubview(getData)
        stackView.addArrangedSubview(confirmDefault)
        stackView.addArrangedSubview(confirmLast)
        stackView.addArrangedSubview(confirm)
        stackView.addArrangedSubview(init3dsButton)
        stackView.addArrangedSubview(generateAReqParamsButton)
        stackView.addArrangedSubview(receiveChallengeParamsButton)
        stackView.addArrangedSubview(doChallengeButton)
        stackView.addArrangedSubview(statusLabel)
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 80).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        reloadButton.setTitle("Reload Client Secret", for: .normal)
        reloadButton.setTitleColor(.white, for: .normal)
        reloadButtonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        reloadButton.configuration = reloadButtonConfiguration
        reloadButton.layer.cornerRadius = 10
        reloadButton.backgroundColor = .systemBlue
        reloadButton.addTarget(self, action: #selector(reload(_:)), for: .touchUpInside)
        
        headlessbutton.setTitle("Initialize Headless", for: .normal)
        headlessbutton.setTitleColor(.white, for: .normal)
        headlessbuttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        headlessbutton.configuration = headlessbuttonConfig
        headlessbutton.layer.cornerRadius = 10
        headlessbutton.addTarget(self, action: #selector(launchHeadless), for: .touchUpInside)

        getDefault.isEnabled = false
        getDefault.setTitle("Get Default Data", for: .normal)
        getDefault.setTitleColor(.white, for: .normal)
        getDefault.addTarget(self, action: #selector(getCustomerDefaultSavedPaymentMethodData), for: .touchUpInside)
        getDefaultConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        getDefault.configuration = getDefaultConfig
        getDefault.layer.cornerRadius = 10
        
        getLast.isEnabled = false
        getLast.setTitle("Get Last Used Data", for: .normal)
        getLast.setTitleColor(.white, for: .normal)
        getLast.addTarget(self, action: #selector(getCustomerLastUsedPaymentMethodData), for: .touchUpInside)
        getLastConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        getLast.configuration = getLastConfig
        getLast.layer.cornerRadius = 10
        
        getData.isEnabled = false
        getData.setTitle("Get Data", for: .normal)
        getData.setTitleColor(.white, for: .normal)
        getData.addTarget(self, action: #selector(getCustomerSavedPaymentMethodData), for: .touchUpInside)
        getDataConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        getData.configuration = getDataConfig
        getData.layer.cornerRadius = 10
        
        confirmDefault.isEnabled = false
        confirmDefault.setTitle("Confirm With Default", for: .normal)
        confirmDefault.setTitleColor(.white, for: .normal)
        confirmDefault.addTarget(self, action: #selector(confirmWithCustomerDefaultPaymentMethod), for: .touchUpInside)
        confirmDefaultConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        confirmDefault.configuration = confirmDefaultConfig
        confirmDefault.layer.cornerRadius = 10
        
        confirmLast.isEnabled = false
        confirmLast.setTitle("Confirm With Last Used", for: .normal)
        confirmLast.setTitleColor(.white, for: .normal)
        confirmLast.addTarget(self, action: #selector(confirmWithCustomerLastUsedPaymentMethod), for: .touchUpInside)
        confirmLastConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        confirmLast.configuration = confirmLastConfig
        confirmLast.layer.cornerRadius = 10
        
        confirm.isEnabled = false
        confirm.setTitle("Confirm With Payment Token", for: .normal)
        confirm.setTitleColor(.white, for: .normal)
        confirm.addTarget(self, action: #selector(confirmWithCustomerPaymentToken), for: .touchUpInside)
        confirmConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        confirm.configuration = confirmConfig
        confirm.layer.cornerRadius = 10
        
        init3dsButton.setTitle("Initialize 3DS", for: .normal)
        init3dsButton.setTitleColor(.white, for: .normal)
        init3dsButton.addTarget(self, action: #selector(initializeThreeDs), for: .touchUpInside)
        init3dsButtonConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        init3dsButtonConfig.baseBackgroundColor = .systemBlue
        init3dsButton.configuration = init3dsButtonConfig
        init3dsButton.layer.cornerRadius = 10
        
        generateAReqParamsButton.setTitle("Generate AReq Params", for: .normal)
        generateAReqParamsButton.setTitleColor(.white, for: .normal)
        generateAReqParamsButton.addTarget(self, action: #selector(generateAReqParams), for: .touchUpInside)
        generateAReqParamsButtonConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        generateAReqParamsButtonConfig.baseBackgroundColor = .systemBlue
        generateAReqParamsButton.configuration = generateAReqParamsButtonConfig
        generateAReqParamsButton.layer.cornerRadius = 10
        
        receiveChallengeParamsButton.setTitle("Receive Challenge Params", for: .normal)
        receiveChallengeParamsButton.setTitleColor(.white, for: .normal)
        receiveChallengeParamsButton.addTarget(self, action: #selector(receiveChallengeParams), for: .touchUpInside)
        receiveChallengeParamsButtonConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        receiveChallengeParamsButtonConfig.baseBackgroundColor = .systemBlue
        receiveChallengeParamsButton.configuration = receiveChallengeParamsButtonConfig
        receiveChallengeParamsButton.layer.cornerRadius = 10
        
        doChallengeButton.setTitle("Do Challenge", for: .normal)
        doChallengeButton.setTitleColor(.white, for: .normal)
        doChallengeButton.addTarget(self, action: #selector(doChallenge), for: .touchUpInside)
        doChallengeButtonConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        doChallengeButtonConfig.baseBackgroundColor = .systemBlue
        doChallengeButton.configuration = doChallengeButtonConfig
        doChallengeButton.layer.cornerRadius = 10
        
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 15
        statusLabel.font = .systemFont(ofSize: 15)
    }
}
