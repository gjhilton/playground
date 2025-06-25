import SwiftUI
import Combine

struct Particle: Identifiable {
    enum State { case flying, splatting, splatted }
    let id = UUID()
    var pos: CGPoint, vel: CGVector, r: CGFloat
    var state = State.flying, splatR: CGFloat = 0
    var color: Color, noiseOff: CGFloat = .random(in:0..<1000)
}

class SpatterSim: ObservableObject {
    @Published var parts: [Particle] = []
    let gravity = CGVector(dx:0,dy:1400), drag:CGFloat=0.92
    let dt:CGFloat = 1/200, groundY:CGFloat=600
    
    func tap(_ p:CGPoint){
        parts.removeAll()
        for _ in 0..<200 {
            let ang = .pi/2 + CGFloat.random(in:-.pi/3...+.pi/3)
            let speed = CGFloat.random(in:800...2200)
            parts.append(.init(pos:p,vel:CGVector(dx:cos(ang)*speed,dy:sin(ang)*speed-200),
                               r: CGFloat.random(in:10...30),
                               color: Color(red:0.3+Double.random(in:0...0.4),
                                            green:0.02, blue:0.02,
                                            opacity: Double.random(in:0.6...1))))
        }
        run()
    }
    
    func run(){
        for _ in 0..<500 {
            for i in parts.indices {
                var pp = parts[i]
                switch pp.state {
                case .flying:
                    pp.vel.dx*=drag; pp.vel.dy=pp.vel.dy*drag+gravity.dy*dt
                    pp.pos.x+=pp.vel.dx*dt; pp.pos.y+=pp.vel.dy*dt
                    if pp.pos.y+pp.r>=groundY {
                        pp.pos.y=groundY-pp.r; pp.state = .splatting; pp.splatR=pp.r
                    }
                case .splatting:
                    pp.splatR += 2
                    if pp.splatR > pp.r*CGFloat.random(in:2.5...5) {
                        pp.state = .splatted; spawnSat(pp)
                    }
                case .splatted: break
                }
                parts[i]=pp
            }
            merge()
        }
        objectWillChange.send()
    }
    
    func spawnSat(_ p: Particle){
        let c = Int.random(in:20...40)
        for _ in 0..<c {
            let ang = CGFloat.random(in:0...2*.pi)
            let sp = CGFloat.random(in:p.r*5...p.r*30)
            let v = CGVector(dx:cos(ang)*sp,dy:-CGFloat.random(in:200...800))
            parts.append(.init(pos:p.pos,vel:v,r:p.r*0.15,color:p.color.opacity(0.7)))
        }
    }
    
    func merge(){
        var used = Set<UUID>(), next:[Particle]=[]
        for p in parts where p.state == .splatted && !used.contains(p.id){
            var grp=[p]; used.insert(p.id)
            for q in parts where q.state == .splatted && !used.contains(q.id){
                if hypot(p.pos.x-q.pos.x,p.pos.y-q.pos.y) < (p.splatR+q.splatR)*0.7 {
                    grp.append(q); used.insert(q.id)
                }
            }
            let x = grp.map{$0.pos.x}.reduce(0,+)/CGFloat(grp.count)
            let y = grp.map{$0.pos.y}.reduce(0,+)/CGFloat(grp.count)
            let R = grp.map{$0.splatR}.max() ?? 0
            next.append(.init(pos:CGPoint(x:x,y:y),vel:.zero,r:R,state:.splatted,splatR:R,color:grp.first!.color,noiseOff:grp.first!.noiseOff))
        }
        let flying = parts.filter{$0.state != .splatted}
        parts = flying + next
    }
    
    func perlin(_ x:CGFloat)->CGFloat{
        let xi = Int(floor(x))&255, xf = x-floor(x)
        let u=xf*xf*xf*(xf*(xf*6-15)+10)
        func g(_ h:Int,_ x:CGFloat)->CGFloat { ((h&1)==0 ? x : -x) }
        let a = g(xi,xf), b=g(xi+1,xf-1)
        return a + u*(b-a)
    }
}

struct ContentView: View {
    @StateObject var s = SpatterSim()
    let w:CGFloat=400,h:CGFloat=700
    
    var body: some View{
        Canvas { ctx, sz in
            ctx.fill(Path(CGRect(origin:.zero,size:sz)), with:.color(.white))
            for p in s.parts {
                if p.state==.flying {
                    let path = drawBlob(at:p.pos,r:p.r,noise: s.perlin(p.noiseOff)*0.5)
                    ctx.blendMode = .plusLighter
                    ctx.fill(path, with:.color(p.color.opacity(0.5)))
                } else {
                    let path = drawBlob(at:p.pos,r:p.splatR,noise:s.perlin(p.noiseOff)*0.7)
                    ctx.blendMode = .multiply
                    ctx.fill(path, with:.color(p.color.opacity(0.85)))
                    let spikes = drawSpikes(at:p.pos,r:p.splatR,noiseOff:p.noiseOff)
                    ctx.blendMode = .multiply
                    ctx.stroke(spikes, with:.color(p.color.opacity(0.6)), lineWidth:1.2)
                }
            }
        }
        .frame(width:w,height:h)
        .gesture(TapGesture().onEnded{s.tap(CGPoint(x:w/2,y:150))})
    }
    
    func drawBlob(at c:CGPoint,r:CGFloat,noise:CGFloat)->Path {
        let n = max(12, Int(r/2))
        var pts=[CGPoint]()
        for i in 0..<n {
            let ang=CGFloat(i)/CGFloat(n)*.pi*2
            let rr=r + noise*r*CGFloat.random(in:-1...1)
            pts.append(CGPoint(x:c.x+cos(ang)*rr,y:c.y+sin(ang)*rr))
        }
        return smooth(pts)
    }
    
    func drawSpikes(at c:CGPoint,r:CGFloat,noiseOff:CGFloat)->Path {
        var p=Path(); let s=Int(r*2)
        for i in 0..<s {
            let ang=CGFloat(i)/CGFloat(s)*.pi*2
            let dist=r*(1+ s.perlin(noiseOff+CGFloat(i)*0.05)*0.2)
            let ex=c.x+cos(ang)*dist, ey=c.y+sin(ang)*dist
            p.move(to: CGPoint(x:c.x+cos(ang)*r,y:c.y+sin(ang)*r))
            p.addLine(to: CGPoint(x:ex,y:ey))
        }
        return p
    }
    
    func smooth(_ pts:[CGPoint])->Path {
        var p=Path()
        guard pts.count>2 else {return p}
        p.move(to:pts[0]); let n=pts.count
        for i in pts.indices {
            let p0=pts[(i-1+n)%n], p1=pts[i], p2=pts[(i+1)%n]
            let d01=hypot(p1.x-p0.x,p1.y-p0.y), d12=hypot(p2.x-p1.x,p2.y-p1.y)
            let sm:CGFloat=0.4
            let cp1=CGPoint(x:p1.x-sm*d01/(d01+d12)*(p2.x-p0.x),y:p1.y-sm*d01/(d01+d12)*(p2.y-p0.y))
            let cp2=CGPoint(x:p1.x+sm*d12/(d01+d12)*(p2.x-p0.x),y:p1.y+sm*d12/(d01+d12)*(p2.y-p0.y))
            p.addCurve(to:p2,control1:cp1,control2:cp2)
        }
        p.closeSubpath()
        return p
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {ContentView()}
}
