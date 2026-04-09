import SwiftUI
import Combine

// 粒子效果数据
struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var color: Color
    var size: CGFloat
    var opacity: Double
    var rotation: Double
    var rotationSpeed: Double
}

// 彩带效果数据
struct Confetti: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var color: Color
    var size: CGSize
    var rotation: Double
    var rotationSpeed: Double
    var oscillation: Double
    var oscillationSpeed: Double
}

class AnimationManager: ObservableObject {
    static let shared = AnimationManager()
    
    @Published var particles: [Particle] = []
    @Published var confetti: [Confetti] = []
    @Published var isAnimatingExplosion = false
    @Published var isAnimatingWin = false
    @Published var showExplosion = false
    @Published var showWin = false
    
    private var explosionTimer: Timer?
    private var confettiTimer: Timer?
    private let particleCount = 30
    private let confettiCount = 50
    
    private init() {}
    
    // MARK: - 爆炸动画
    
    func triggerExplosion(at position: CGPoint, in size: CGSize) {
        guard ThemeManager.shared.enableAnimations else { return }
        
        showExplosion = true
        isAnimatingExplosion = true
        
        // 创建爆炸粒子
        particles = (0..<particleCount).map { _ in
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 100...300)
            let velocity = CGVector(
                dx: cos(angle) * speed,
                dy: sin(angle) * speed
            )
            
            return Particle(
                position: position,
                velocity: velocity,
                color: [.red, .orange, .yellow, .white].randomElement()!,
                size: CGFloat.random(in: 4...12),
                opacity: 1.0,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -360...360)
            )
        }
        
        // 动画更新
        var elapsed: TimeInterval = 0
        let duration: TimeInterval = 1.0
        let interval: TimeInterval = 0.016 // 60fps
        
        explosionTimer?.invalidate()
        explosionTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            elapsed += interval
            
            if elapsed >= duration {
                timer.invalidate()
                self.showExplosion = false
                self.isAnimatingExplosion = false
                self.particles.removeAll()
                return
            }
            
            // 更新粒子
            self.updateParticles(dt: interval)
        }
    }
    
    private func updateParticles(dt: TimeInterval) {
        let gravity: CGFloat = 500
        let drag: CGFloat = 0.98
        
        particles = particles.map { particle in
            var newParticle = particle
            
            // 应用重力
            newParticle.velocity.dy += gravity * CGFloat(dt)
            
            // 应用阻力
            newParticle.velocity.dx *= drag
            newParticle.velocity.dy *= drag
            
            // 更新位置
            newParticle.position.x += newParticle.velocity.dx * CGFloat(dt)
            newParticle.position.y += newParticle.velocity.dy * CGFloat(dt)
            
            // 更新旋转
            newParticle.rotation += newParticle.rotationSpeed * dt
            
            // 淡出
            newParticle.opacity -= dt * 0.8
            
            return newParticle
        }.filter { $0.opacity > 0 }
    }
    
    // MARK: - 胜利动画
    
    func triggerWinAnimation(in size: CGSize) {
        guard ThemeManager.shared.enableAnimations else { return }
        
        showWin = true
        isAnimatingWin = true
        
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .cyan]
        
        // 创建彩带
        confetti = (0..<confettiCount).map { _ in
            let startX = CGFloat.random(in: 0...size.width)
            let velocity = CGVector(
                dx: CGFloat.random(in: -100...100),
                dy: CGFloat.random(in: -800...(-400))
            )
            
            return Confetti(
                position: CGPoint(x: startX, y: size.height + 20),
                velocity: velocity,
                color: colors.randomElement()!,
                size: CGSize(width: CGFloat.random(in: 8...16), height: CGFloat.random(in: 4...8)),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -180...180),
                oscillation: 0,
                oscillationSpeed: Double.random(in: 3...8)
            )
        }
        
        // 动画更新
        var elapsed: TimeInterval = 0
        let duration: TimeInterval = 3.0
        let interval: TimeInterval = 0.016
        
        confettiTimer?.invalidate()
        confettiTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            elapsed += interval
            
            if elapsed >= duration {
                timer.invalidate()
                self.showWin = false
                self.isAnimatingWin = false
                self.confetti.removeAll()
                return
            }
            
            // 更新彩带
            self.updateConfetti(dt: interval, screenHeight: size.height)
        }
    }
    
    private func updateConfetti(dt: TimeInterval, screenHeight: CGFloat) {
        let gravity: CGFloat = 400
        let drag: CGFloat = 0.99
        
        confetti = confetti.map { conf in
            var newConf = conf
            
            // 应用重力
            newConf.velocity.dy += gravity * CGFloat(dt)
            
            // 应用阻力
            newConf.velocity.dx *= drag
            newConf.velocity.dy *= drag
            
            // 摆动效果
            newConf.oscillation += newConf.oscillationSpeed * dt
            let oscillationOffset = sin(newConf.oscillation) * 30 * CGFloat(dt)
            
            // 更新位置
            newConf.position.x += (newConf.velocity.dx + oscillationOffset) * CGFloat(dt)
            newConf.position.y += newConf.velocity.dy * CGFloat(dt)
            
            // 更新旋转
            newConf.rotation += newConf.rotationSpeed * dt
            
            return newConf
        }.filter { $0.position.y < screenHeight + 50 }
    }
    
    func stopAllAnimations() {
        explosionTimer?.invalidate()
        confettiTimer?.invalidate()
        particles.removeAll()
        confetti.removeAll()
        showExplosion = false
        showWin = false
        isAnimatingExplosion = false
        isAnimatingWin = false
    }
}

// MARK: - 爆炸效果视图
struct ExplosionEffectView: View {
    @StateObject private var animationManager = AnimationManager.shared
    
    var body: some View {
        ZStack {
            ForEach(animationManager.particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .rotationEffect(.degrees(particle.rotation))
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 胜利彩带效果视图
struct ConfettiEffectView: View {
    @StateObject private var animationManager = AnimationManager.shared
    
    var body: some View {
        ZStack {
            ForEach(animationManager.confetti) { conf in
                Rectangle()
                    .fill(conf.color)
                    .frame(width: conf.size.width, height: conf.size.height)
                    .position(conf.position)
                    .rotationEffect(.degrees(conf.rotation))
                    .cornerRadius(2)
            }
        }
        .allowsHitTesting(false)
    }
}
