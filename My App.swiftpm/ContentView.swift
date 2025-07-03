import SwiftUI

struct QuakeRenderer: TextRenderer {
    var moveAmount: Double
    
    var animatableData: Double {
        get { moveAmount }
        set { moveAmount = newValue }
    }
    
    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            for run in line {
                for glyph in run {
                    var copy = context
                    let yOffset = Double.random(in: -moveAmount...moveAmount)
                    
                    copy.translateBy(x: 0, y: yOffset)
                    copy.draw(glyph, options: .disablesSubpixelQuantization)
                }
            }
        }
    }
}

struct ContentView: View {
    @State private var strength = 0.0
    
    var body: some View {
        Text("SHOCKWAVE")
            .font(.largeTitle.weight(.black).width(.compressed))
            .textRenderer(QuakeRenderer(moveAmount: strength))
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    strength = 10
                }
            }
    }
}





