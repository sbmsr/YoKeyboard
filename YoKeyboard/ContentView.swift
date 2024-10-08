//
//  ContentView.swift
//  YoKeyboard
//
//  Created by Sebastian Messier on 4/14/23.
//

import SwiftUI


struct ContentView: View {
    @State private var text: String = ""

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            Text("please type the following text!")
            Text("qqwwqqwwqq")
            TextField("", text: $text)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
