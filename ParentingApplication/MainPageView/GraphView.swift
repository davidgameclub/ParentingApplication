//
//  GraphView.swift
//  ParentingApplication_second
//
//  Created by Assistant on [Current Date].
//

import SwiftUI

struct GraphView: View {
    var body: some View {
        VStack {
            Image(systemName: "chart.xyaxis.line")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.blue)
                .padding()
            
            Text("Graph Page")
                .font(.title)
                .fontWeight(.bold)
        }
        .navigationTitle("Graph")
    }
}

#Preview {
    NavigationStack {
        GraphView()
    }
}
