//
//  ContentView.swift
//  Hyperswitch
//
//  Created by Shivam Shashank on 09/12/22.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedSegment = 0

    var body: some View {
        VStack {
            Picker(selection: $selectedSegment, label: Text("")) {
                Text("UIKit View").tag(0)
                Text("SwiftUI View").tag(1)
                Text("Headless View").tag(2)
                Text("3DS").tag(3)
                Text("C2P").tag(4)
                Text("Widget").tag(5)
                Text("PM").tag(6)
                Text("PMM").tag(7)
            }.pickerStyle(SegmentedPickerStyle())

            switch selectedSegment {
            case 0:
                UIKitView()
            case 1:
                SwiftUIView()
            case 2:
                HeadlessView()
            case 3:
                ThreeDSView()
            case 4:
                ClickToPayView()
            case 5:
                WidgetView()
            case 6:
                PaymentMethodsView()
            case 7:
                PMMView()
            default:
                UIKitView()
            }
        }
    }
}
struct PaymentMethodsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = PaymentMethodsViewController

    func makeUIViewController(context: Context) -> PaymentMethodsViewController {
        return PaymentMethodsViewController()
    }

    func updateUIViewController(_ uiViewController: PaymentMethodsViewController, context: Context) {
    }
}

struct HeadlessView: UIViewControllerRepresentable {
    typealias UIViewControllerType = HeadlessViewController

    func makeUIViewController(context: Context) -> HeadlessViewController {
        return HeadlessViewController()
    }

    func updateUIViewController(_ uiViewController: HeadlessViewController, context: Context) {
    }
}

struct UIKitView: UIViewControllerRepresentable {
    typealias UIViewControllerType = ViewController

    func makeUIViewController(context: Context) -> ViewController {
        return ViewController()
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
    }
}

struct ThreeDSView: UIViewControllerRepresentable {
    typealias UIViewControllerType = AuthenticationViewController

    func makeUIViewController(context: Context) -> AuthenticationViewController {
        return AuthenticationViewController()
    }

    func updateUIViewController(_ uiViewController: AuthenticationViewController, context: Context) {
    }
}

struct ClickToPayView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UINavigationController

    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: ClickToPayViewController())
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}

struct WidgetView: UIViewControllerRepresentable {
    typealias UIViewControllerType = WidgetViewController

    func makeUIViewController(context: Context) -> WidgetViewController {
        return WidgetViewController()
    }

    func updateUIViewController(_ uiViewController: WidgetViewController, context: Context) {
    }
}

struct PMMView: UIViewControllerRepresentable {
    typealias UIViewControllerType = PaymentMethodManagementViewController

    func makeUIViewController(context: Context) -> PaymentMethodManagementViewController {
        return PaymentMethodManagementViewController()
    }

    func updateUIViewController(_ uiViewController: PaymentMethodManagementViewController, context: Context) {
    }
}
