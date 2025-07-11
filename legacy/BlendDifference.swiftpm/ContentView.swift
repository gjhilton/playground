import SwiftUI

struct ContentView: View {
    @State private var offsetX: CGFloat = -150 // start off left
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            Rectangle()
                .fill(Color.black)
                .frame(width: 250, height: 100)
                .position(x: 200, y: 200)
            
            Text("Blend Mode Text")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .blendMode(.difference)
                .position(x: 200 + offsetX, y: 200)
                .onAppear {
                    let distance: CGFloat = 300 // total horizontal distance to move
                    offsetX = -distance / 2
                    withAnimation(
                        Animation.linear(duration: 3)
                            .repeatForever(autoreverses: true)
                    ) {
                        offsetX = distance / 2
                    }
                }
        }
    }
}
