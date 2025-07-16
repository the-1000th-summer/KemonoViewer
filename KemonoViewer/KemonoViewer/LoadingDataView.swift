//
//  LoadingDataView.swift
//  KemonoViewer
//
//  Created on 2025/7/16.
//

import SwiftUI

struct LoadingDataView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading data from database...")
                .font(.title)
        }
    }
}

#Preview {
    LoadingDataView()
}
