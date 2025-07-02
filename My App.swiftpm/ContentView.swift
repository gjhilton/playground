import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            Text("Blend Mode Text")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .position(x: 200, y: 200)
            Rectangle()
                .fill(Color.white)
                .frame(width: 250, height: 100)
                .position(x: 200, y: 200)
                .blendMode(.difference)
            
        }
    }
}
