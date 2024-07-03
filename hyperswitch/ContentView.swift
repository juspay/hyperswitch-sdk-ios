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
                Text("Headless View").tag(0)
                Text("UIKit View").tag(1)
                Text("SwiftUI View").tag(2)
            }.pickerStyle(SegmentedPickerStyle())
            if selectedSegment == 0 {
                HeadlessView()
            }
            else if selectedSegment == 1{
                UIKitView()
            }
            else {
                SwiftUIView()
            }
        }
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
