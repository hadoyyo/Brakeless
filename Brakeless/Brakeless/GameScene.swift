//
//  GameScene.swift
//  Brakeless
//
//  Created by Hubert on 08/04/2025.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Game Variables
    private var car: SKSpriteNode!
    private var scoreLabel: SKLabelNode!
    private var highScoreLabel: SKLabelNode!
    private var totalCoinsLabel: SKLabelNode!
    private var coinIcon: SKSpriteNode!
    private var score = 0 {
        didSet {
            scoreLabel.text = "SCORE: \(score)"
            scoreLabel.fontSize = 30
        }
    }
    
    private var highScore = UserDefaults.standard.integer(forKey: "highScore") {
        didSet {
            highScoreLabel.text = "BEST: \(highScore)"
        }
    }
    
    private var totalCoins = UserDefaults.standard.integer(forKey: "totalCoins") {
        didSet {
            totalCoinsLabel.text = "\(totalCoins)"
            UserDefaults.standard.set(totalCoins, forKey: "totalCoins")
        }
    }
    
    private var coinsInThisRun = 0 {
        didSet {
            if coinsInThisRun % 10 == 0 {
                increaseSpeed()
            }
        }
    }
    
    private var isGameOver = false
    private var touchLocation: CGPoint?
    private var baseRoadSpeed: CGFloat = 5.0
    private var roadSpeed: CGFloat = 5.0
    private var lastSmokeTime: TimeInterval = 0
    private var shieldDisableAction: SKAction?
    
    // Sound
    private var backgroundMusic: SKAudioNode!
    private var currentBiomeMusic: String = ""
    
    // Powerup
    private var isShielded = false {
        didSet {
            shieldVisual.isHidden = !isShielded
        }
    }
    private var isBoosted = false
    private var shieldEndTime: TimeInterval = 0
    private var boostEndTime: TimeInterval = 0
    private var shieldVisual: SKSpriteNode!
    
    // Object sizes
    private let carSize = CGSize(width: 50, height: 80)
    private let coinSize = CGSize(width: 30, height: 30)
    private let obstacleSize = CGSize(width: 50, height: 50)
    
    // Collision categories
    private let carCategory: UInt32 = 0x1 << 0
    private let coinCategory: UInt32 = 0x1 << 1
    private let obstacleCategory: UInt32 = 0x1 << 2
    private let cashCategory: UInt32 = 0x1 << 3
    private let powerupCategory: UInt32 = 0x1 << 4
    
    // Lane system
    private let numberOfLanes = 6
    private var laneWidth: CGFloat = 0
    private var lanePositions: [CGFloat] = []
    
    private var carTiltAngle: CGFloat = 0.0
    private let maxTiltAngle: CGFloat = 0.3
    private let tiltReturnSpeed: CGFloat = 0.05
    
    private var isTouching = false
    
    // Biome variables
    private let biomes: [Biome] = [
        Biome(name: "CITY", texturePrefix: "city_road", color: SKColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0), obstacleSpeed: 1.0),
        Biome(name: "FOREST", texturePrefix: "forest_road", color: SKColor(red: 0.1, green: 0.3, blue: 0.1, alpha: 1.0), obstacleSpeed: 1.0),
        Biome(name: "DESERT", texturePrefix: "desert_road", color: SKColor(red: 0.8, green: 0.7, blue: 0.4, alpha: 1.0), obstacleSpeed: 1.0),
        Biome(name: "WINTER", texturePrefix: "winter_road", color: SKColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0), obstacleSpeed: 1.0),
        Biome(name: "HIGHWAY", texturePrefix: "highway_road", color: SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0), obstacleSpeed: 1.0)
    ]
    
    private var currentBiomeIndex = 0
    private var nextBiomeIndex = 1
    private var isTransitioningBiome = false
    private var transitionProgress: CGFloat = 0.0
    private var biomeChangeInterval: TimeInterval = 30.0
    private var lastBiomeChangeTime: TimeInterval = 0.0
    private var transitionRoadPlaced = false
    
    // Obstacle types
    private enum ObstacleType: Int, CaseIterable {
        case smallObstacle = 0
        case smallCar
        case truck
        case log
        case wideTruck
        case boulder
        
        var widthInLanes: Int {
            switch self {
            case .smallObstacle: return 1
            case .smallCar: return 1
            case .truck: return 1
            case .log: return 3
            case .wideTruck: return 2
            case .boulder: return 3
            }
        }
        
        var lengthMultiplier: CGFloat {
            switch self {
            case .smallObstacle: return 1.4
            case .smallCar: return 1.8
            case .truck: return 4
            case .log: return 1
            case .wideTruck: return 3
            case .boulder: return 3
            }
        }
        
        var heightMultiplier: CGFloat {
            switch self {
            case .smallObstacle: return 1.0
            case .smallCar: return 1.0
            case .truck: return 1.0
            case .log: return 1.0
            case .wideTruck: return 1.0
            case .boulder: return 1.0
            }
        }
        
        var speedMultiplier: CGFloat {
            switch self {
            case .smallObstacle: return 0.6
            case .smallCar: return 0.38
            case .truck: return 0.5
            case .log: return 0.7692
            case .wideTruck: return 0.7692
            case .boulder: return 0.7692
            }
        }
        
        var shouldMoveWithRoad: Bool {
            switch self {
            case .log, .wideTruck, .boulder:
                return true
            default:
                return false
            }
        }
        
        func textureName(for biome: Biome) -> String {
            let prefix = biome.texturePrefix
            switch self {
            case .smallObstacle:
                let variant = Int.random(in: 1...3)
                return "\(prefix)_small_obstacle\(variant)"
            case .smallCar:
                let variant = Int.random(in: 1...4)
                return "\(prefix)_car\(variant)"
            case .truck:
                let variant = Int.random(in: 1...4)
                return "\(prefix)_truck\(variant)"
            case .log: return "\(prefix)_log"
            case .wideTruck: return "\(prefix)_widetruck"
            case .boulder: return "\(prefix)_boulder"
            }
        }
    }
    
    struct Biome {
        let name: String
        let texturePrefix: String
        let color: SKColor
        let obstacleSpeed: CGFloat
        
        func roadTexture() -> SKTexture {
            return SKTexture(imageNamed: texturePrefix)
        }
        
        func transitionTexture(to biome: Biome) -> SKTexture? {
            if (self.name == "DESERT" && biome.name == "WINTER") || (self.name == "WINTER" && biome.name == "DESERT") {
                return nil
            }
            return SKTexture(imageNamed: "\(self.texturePrefix)_to_\(biome.texturePrefix)")
        }
    }
    
    // MARK: - Game Setup
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        backgroundColor = biomes[currentBiomeIndex].color
        
        // Calculate lane positions
        laneWidth = size.width / CGFloat(numberOfLanes)
        lanePositions = (0..<numberOfLanes).map { CGFloat($0) * laneWidth + laneWidth / 2 }
        
        setupRoad()
        setupCar()
        setupUI()
        preloadSounds()
        playBiomeMusic(biome: biomes[currentBiomeIndex])
        startGame()
    }
    
    private func preloadSounds() {
        let soundFiles = ["boost.wav", "coin.wav", "crash.wav", "shield.wav", "shielded_block.wav", "shield_off.wav"]
        for sound in soundFiles {
            if let url = Bundle.main.url(forResource: sound, withExtension: nil) {
                do {
                    _ = try AVAudioPlayer(contentsOf: url)
                } catch {
                    print("Error preloading sound \(sound): \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    private func playBiomeMusic(biome: Biome) {
        
        if UserDefaults.standard.bool(forKey: "musicDisabled") {
            return
        }
        
        let musicFile: String
        switch biome.name {
        case "CITY": musicFile = "city.mp3"
        case "FOREST": musicFile = "forest.mp3"
        case "DESERT": musicFile = "desert.mp3"
        case "WINTER": musicFile = "winter.mp3"
        case "HIGHWAY": musicFile = "highway.mp3"
        default: musicFile = "city.mp3"
        }
        
        if currentBiomeMusic == musicFile { return }
        
        if let oldMusic = backgroundMusic {
            oldMusic.run(SKAction.sequence([
                SKAction.changeVolume(to: 0, duration: 1.0),
                SKAction.removeFromParent()
            ]))
        }
        
        // Play new biome music
        if let url = Bundle.main.url(forResource: musicFile, withExtension: nil) {
            backgroundMusic = SKAudioNode(url: url)
            backgroundMusic.autoplayLooped = true
            backgroundMusic.run(SKAction.changeVolume(to: 0, duration: 0))
            addChild(backgroundMusic)
            
            backgroundMusic.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.changeVolume(to: 1, duration: 1.0)
            ]))
        }
        
        currentBiomeMusic = musicFile
    }
    
    private func playSoundEffect(named fileName: String) {
        if UserDefaults.standard.bool(forKey: "soundEffectsDisabled") {
            return
        }
        let adjustedVolume: Float = 0
        let playAction = SKAction.playSoundFileNamed(fileName, waitForCompletion: false)
        let volumeAction = SKAction.changeVolume(to: adjustedVolume, duration: 0.1)
        run(SKAction.group([playAction, volumeAction]))
    }
    
    
    private func setupRoad() {
        for i in 0..<2 {
            let road = SKSpriteNode(texture: biomes[currentBiomeIndex].roadTexture())
            road.zPosition = -1
            road.anchorPoint = CGPoint(x: 0.5, y: 0)
            road.position = CGPoint(x: size.width / 2, y: size.height * CGFloat(i))
            road.size = CGSize(width: size.width, height: size.height)
            road.name = "road"
            addChild(road)
        }
    }
    
    private func setupCar() {
        let selectedCar = UserDefaults.standard.string(forKey: "selectedCar") ?? "car"
        car = SKSpriteNode(imageNamed: selectedCar)
        car.size = carSize
        car.position = CGPoint(x: size.width / 2, y: 100)
        car.zPosition = 10
        car.name = "car"
        
        car.physicsBody = SKPhysicsBody(rectangleOf: carSize)
        car.physicsBody?.categoryBitMask = carCategory
        car.physicsBody?.contactTestBitMask = coinCategory | obstacleCategory | cashCategory | powerupCategory
        car.physicsBody?.collisionBitMask = 0
        car.physicsBody?.isDynamic = true
        car.physicsBody?.affectedByGravity = false
        
        // Shield visual
        shieldVisual = SKSpriteNode(imageNamed: "shielded")
        shieldVisual.size = CGSize(width: 66, height: 99)
        shieldVisual.zPosition = 11
        shieldVisual.isHidden = true
        car.addChild(shieldVisual)
        
        addChild(car)
    }
    
    private func setupUI() {
        scoreLabel = SKLabelNode(text: "SCORE: 0")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: size.height - 70)
        scoreLabel.zPosition = 100
        addChild(scoreLabel)
        
        highScoreLabel = SKLabelNode(text: "BEST: \(highScore)")
        highScoreLabel.fontName = "AvenirNext-Bold"
        highScoreLabel.fontSize = 20
        highScoreLabel.fontColor = SKColor(hex: "FFD500")
        highScoreLabel.horizontalAlignmentMode = .left
        highScoreLabel.position = CGPoint(x: 16, y: size.height - 100)
        highScoreLabel.zPosition = 100
        addChild(highScoreLabel)
        
        coinIcon = SKSpriteNode(imageNamed: "coin")
        coinIcon.size = CGSize(width: 20, height: 20)
        coinIcon.position = CGPoint(x: size.width - 30, y: size.height - 52)
        coinIcon.zPosition = 100
        addChild(coinIcon)
        
        totalCoinsLabel = SKLabelNode(text: "\(totalCoins)")
        totalCoinsLabel.fontName = "AvenirNext-Bold"
        totalCoinsLabel.fontSize = 20
        totalCoinsLabel.fontColor = .white
        totalCoinsLabel.horizontalAlignmentMode = .right
        totalCoinsLabel.position = CGPoint(x: size.width - 50, y: size.height - 60)
        totalCoinsLabel.zPosition = 100
        addChild(totalCoinsLabel)
    }
    
    private func startGame() {
        isGameOver = false
        score = 0
        coinsInThisRun = 0
        lastSmokeTime = 0
        lastBiomeChangeTime = CACurrentMediaTime()
        transitionRoadPlaced = false
        isShielded = false
        isBoosted = false
        baseRoadSpeed = 5.0
        roadSpeed = 5.0
        shieldDisableAction = nil
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(spawnCoin),
                SKAction.wait(forDuration: 1.0)
            ])
        ), withKey: "coinSpawn")
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(spawnObstacle),
                SKAction.wait(forDuration: 1.5)
            ])
        ), withKey: "obstacleSpawn")
    }
    
    private func increaseSpeed() {
        baseRoadSpeed += 0.25
        if !isBoosted {
            roadSpeed = baseRoadSpeed
        }
    }
    
    // MARK: - Object Generation
    private func spawnCoin() {
        guard !isGameOver else { return }
        
        // 5% chance to spawn
        if Int.random(in: 1...20) == 1 {
            spawnCash()
            return
        }
        
        let coin = SKSpriteNode(imageNamed: "coin")
        coin.size = coinSize
        
        let randomLane = Int.random(in: 0..<numberOfLanes)
        coin.position = CGPoint(
            x: lanePositions[randomLane],
            y: size.height + coinSize.height
        )
        
        coin.zPosition = 5
        coin.name = "coin"
        
        coin.physicsBody = SKPhysicsBody(circleOfRadius: coinSize.width / 2)
        coin.physicsBody?.categoryBitMask = coinCategory
        coin.physicsBody?.contactTestBitMask = carCategory
        coin.physicsBody?.collisionBitMask = 0
        coin.physicsBody?.isDynamic = false
        
        addChild(coin)
    }
    
    private func spawnCash() {
        let cash = SKSpriteNode(imageNamed: "cash")
        cash.size = coinSize
        
        let randomLane = Int.random(in: 0..<numberOfLanes)
        cash.position = CGPoint(
            x: lanePositions[randomLane],
            y: size.height + coinSize.height
        )
        
        cash.zPosition = 5
        cash.name = "cash"
        
        cash.physicsBody = SKPhysicsBody(circleOfRadius: coinSize.width / 2)
        cash.physicsBody?.categoryBitMask = cashCategory
        cash.physicsBody?.contactTestBitMask = carCategory
        cash.physicsBody?.collisionBitMask = 0
        cash.physicsBody?.isDynamic = false
        
        addChild(cash)
    }
    
    private func spawnPowerup() {
        guard !isGameOver else { return }
        
        // 5% chance to spawn
        if Int.random(in: 1...10) != 1 {
            return
        }
        
        let powerupType = Int.random(in: 1...2) // 1 = shield, 2 = boost
        let powerup = SKSpriteNode(imageNamed: powerupType == 1 ? "shield" : "boost")
        powerup.size = coinSize
        
        let randomLane = Int.random(in: 0..<numberOfLanes)
        powerup.position = CGPoint(
            x: lanePositions[randomLane],
            y: size.height + coinSize.height
        )
        
        powerup.zPosition = 5
        powerup.name = "powerup"
        
        powerup.physicsBody = SKPhysicsBody(circleOfRadius: coinSize.width / 2)
        powerup.physicsBody?.categoryBitMask = powerupCategory
        powerup.physicsBody?.contactTestBitMask = carCategory
        powerup.physicsBody?.collisionBitMask = 0
        powerup.physicsBody?.isDynamic = false
        
        powerup.userData = NSMutableDictionary()
        powerup.userData?.setValue(powerupType, forKey: "powerupType")
        
        addChild(powerup)
    }
    
    private func spawnObstacle() {
        guard !isGameOver && !isTransitioningBiome else { return }

        let obstacleType: ObstacleType
        let randomValue = Int.random(in: 1...100)

        if randomValue <= 25 {
            obstacleType = .smallObstacle
        } else if randomValue <= 55 {
            obstacleType = .smallCar
        } else if randomValue <= 75 {
            obstacleType = .truck
        } else if randomValue <= 85 {
            obstacleType = .log
        } else if randomValue <= 95 {
            obstacleType = .wideTruck
        } else {
            obstacleType = .boulder
        }

        let isWinterBiome = biomes[currentBiomeIndex].name == "WINTER"
        let isForestBiome = biomes[currentBiomeIndex].name == "FOREST"
        let isDesertBiome = biomes[currentBiomeIndex].name == "DESERT"
        let isRestrictedObstacle = (obstacleType == .wideTruck || obstacleType == .boulder || obstacleType == .truck)

        let maxLane = numberOfLanes - obstacleType.widthInLanes
        var startLane: Int

        if isWinterBiome {
            if obstacleType == .wideTruck {
                let availableLanes = [0, 4].filter { $0 <= maxLane }
                startLane = availableLanes.randomElement() ?? 0
            } else if obstacleType == .boulder {
                let availableLanes = [0, 3].filter { $0 <= maxLane }
                startLane = availableLanes.randomElement() ?? 0
            } else {
                startLane = Int.random(in: 0...maxLane)
            }
        } else if isForestBiome && isRestrictedObstacle {
            if obstacleType == .truck {
                let availableLanes = [2, 3].filter { $0 <= maxLane }
                startLane = availableLanes.randomElement() ?? 2
            } else {
                let availableLanes = [0, 3, 4, 5].filter { $0 <= maxLane }
                startLane = availableLanes.randomElement() ?? 0
            }
        } else if isDesertBiome && obstacleType == .wideTruck {
            let availableLanes = [0, 4].filter { $0 <= maxLane }
            startLane = availableLanes.randomElement() ?? 0
        } else if currentBiomeIndex == biomes.firstIndex(where: { $0.name == "HIGHWAY" }) ||
                  (obstacleType != .smallCar && obstacleType != .truck) {
            startLane = Int.random(in: 0...maxLane)
        } else {
            let availableLanes = 1..<(numberOfLanes-1)
            startLane = availableLanes.randomElement() ?? 1
        }

        let centerX = (lanePositions[startLane] + lanePositions[startLane + obstacleType.widthInLanes - 1]) / 2

        let width = laneWidth * CGFloat(obstacleType.widthInLanes) * 0.8
        let height = obstacleSize.height * obstacleType.lengthMultiplier * obstacleType.heightMultiplier

        let textureName = obstacleType.textureName(for: biomes[currentBiomeIndex])
        let obstacle = SKSpriteNode(imageNamed: textureName)
        obstacle.size = CGSize(width: width, height: height)
        obstacle.position = CGPoint(
            x: centerX,
            y: size.height + height
        )

        if isDesertBiome && obstacleType == .log {
            let moveDirection = Bool.random() ? 1 : -1
            obstacle.userData = NSMutableDictionary()
            obstacle.userData?.setValue(obstacleType.rawValue, forKey: "obstacleType")
            obstacle.userData?.setValue(obstacleType.speedMultiplier, forKey: "speedMultiplier")
            obstacle.userData?.setValue(moveDirection, forKey: "moveDirection")
            
            if moveDirection == -1 {
                obstacle.xScale = -1
            }
        } else {
            obstacle.userData = NSMutableDictionary()
            obstacle.userData?.setValue(obstacleType.rawValue, forKey: "obstacleType")
            obstacle.userData?.setValue(obstacleType.speedMultiplier, forKey: "speedMultiplier")
        }

        obstacle.zPosition = 5
        obstacle.name = "obstacle"

        obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacle.physicsBody?.categoryBitMask = obstacleCategory
        obstacle.physicsBody?.contactTestBitMask = carCategory | obstacleCategory
        obstacle.physicsBody?.collisionBitMask = obstacleCategory
        obstacle.physicsBody?.isDynamic = true
        obstacle.physicsBody?.affectedByGravity = false
        obstacle.physicsBody?.restitution = 0.3

        addChild(obstacle)
    }
    
    // MARK: - Game Logic
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchLocation = touch.location(in: self)
        isTouching = true
        
        if isGameOver {
            guard let touch = touches.first else { return }
            let touchLocation = touch.location(in: self)
            let nodes = self.nodes(at: touchLocation)
            
            if nodes.contains(where: { $0.name == "restartButton" }) {
                restartGame()
            } else if nodes.contains(where: { $0.name == "menuButton" }) {
                returnToMenu()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver, let touch = touches.first, let touchLocation = touchLocation else { return }
        let newLocation = touch.location(in: self)
        let deltaX = newLocation.x - touchLocation.x
        
        car.position.x += deltaX
        car.position.x = max(carSize.width/2, min(car.position.x, size.width - carSize.width/2))
        
        carTiltAngle = -deltaX * 0.01
        carTiltAngle = max(-maxTiltAngle, min(maxTiltAngle, carTiltAngle))
        car.zRotation = carTiltAngle
        
        let currentTime = CACurrentMediaTime()
        if currentTime - lastSmokeTime > 0.1 {
            spawnTireSmoke()
            lastSmokeTime = currentTime
        }
        
        self.touchLocation = newLocation
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        touchLocation = nil
    }
    
    // MARK: - Collision Handling
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == carCategory | coinCategory {
            handleCoinCollision(contact: contact)
        }
        else if collision == carCategory | cashCategory {
            handleCashCollision(contact: contact)
        }
        else if collision == carCategory | powerupCategory {
            handlePowerupCollision(contact: contact)
        }
        else if collision == carCategory | obstacleCategory {
            handleObstacleCollisionWithCar(contact: contact)
        }
        else if collision == obstacleCategory | obstacleCategory {
            handleObstacleCollision(contact: contact)
        }
    }
    
    private func handleCoinCollision(contact: SKPhysicsContact) {
        let coinNode = contact.bodyA.categoryBitMask == coinCategory ? contact.bodyA.node : contact.bodyB.node
        let coinPosition = coinNode?.position ?? CGPoint.zero
        
        spawnCoinEffect(at: coinPosition)
        coinNode?.removeFromParent()
        
        score += 1
        totalCoins += 1
        coinsInThisRun += 1
        playSoundEffect(named: "coin.wav")
    }
    
    private func handleCashCollision(contact: SKPhysicsContact) {
        let cashNode = contact.bodyA.categoryBitMask == cashCategory ? contact.bodyA.node : contact.bodyB.node
        let cashPosition = cashNode?.position ?? CGPoint.zero
        
        spawnCoinEffect(at: cashPosition)
        cashNode?.removeFromParent()
        
        score += 5
        totalCoins += 5
        coinsInThisRun += 5
        playSoundEffect(named: "coin.wav")
    }
    
    private func handlePowerupCollision(contact: SKPhysicsContact) {
        let powerupNode = contact.bodyA.categoryBitMask == powerupCategory ? contact.bodyA.node : contact.bodyB.node
        let powerupPosition = powerupNode?.position ?? CGPoint.zero
        
        spawnPowerupEffect(at: powerupPosition)
        powerupNode?.removeFromParent()
        
        guard let userData = powerupNode?.userData as? [String: Any],
              let powerupType = userData["powerupType"] as? Int else {
            return
        }
        
        if powerupType == 1 { // Shield
            isShielded = true
            shieldEndTime = CACurrentMediaTime() + 10.0
            
            removeAction(forKey: "shieldDisable")
            shieldDisableAction = nil
            
            let waitAction = SKAction.wait(forDuration: 10.0)
            let disableShield = SKAction.run { [weak self] in
                
                self?.spawnShieldDisappearEffect(naturalExpiration: true)
                self?.isShielded = false
            }
            
            shieldDisableAction = disableShield
            
            run(SKAction.sequence([waitAction, disableShield]), withKey: "shieldDisable")
            
            // Shield sound
            playSoundEffect(named: "shield.wav")
            
        } else if powerupType == 2 { // Boost
            isBoosted = true
            boostEndTime = CACurrentMediaTime() + 5.0
            roadSpeed = baseRoadSpeed + 3.0
            
            removeAction(forKey: "boostDisable")
            
            let waitAction = SKAction.wait(forDuration: 5.0)
            let disableBoost = SKAction.run { [weak self] in
                self?.isBoosted = false
                self?.roadSpeed = self?.baseRoadSpeed ?? 5.0
            }
            
            run(SKAction.sequence([waitAction, disableBoost]), withKey: "boostDisable")
            
            // Boost sound
            playSoundEffect(named: "boost.wav")
        }
    }
    private func handleObstacleCollisionWithCar(contact: SKPhysicsContact) {
        if isShielded {
            let obstacleNode = contact.bodyA.categoryBitMask == obstacleCategory ? contact.bodyA.node : contact.bodyB.node
            obstacleNode?.removeFromParent()
            spawnShieldDisappearEffect()
            isShielded = false
            
            removeAction(forKey: "shieldDisable")
            shieldDisableAction = nil
            
            playSoundEffect(named: "shielded_block.wav")
        } else {
            gameOver()
        }
    }
    
    private func handleObstacleCollision(contact: SKPhysicsContact) {
        let obstacle1 = contact.bodyA.node as? SKSpriteNode
        let obstacle2 = contact.bodyB.node as? SKSpriteNode
        
        applyObstacleCollisionEffect(to: obstacle1)
        applyObstacleCollisionEffect(to: obstacle2)
    }
    
    private func applyObstacleCollisionEffect(to obstacle: SKSpriteNode?) {
        guard let obstacle = obstacle else { return }
        obstacle.userData?.setValue(0.0, forKey: "speedMultiplier")
        obstacle.userData?.setValue(0, forKey: "moveDirection")
        obstacle.physicsBody?.isDynamic = false
        obstacle.physicsBody?.velocity = CGVector.zero
        obstacle.physicsBody?.angularVelocity = 0
    }
    
    // MARK: - Shield Effect
    private func spawnShieldDisappearEffect(naturalExpiration: Bool = false) {
        let effect = SKSpriteNode(imageNamed: "glow1")
        effect.position = car.position
        effect.zPosition = 15
        effect.setScale(0.8)
        effect.color = SKColor.black
        effect.colorBlendFactor = 0.8
        
        let animation = SKAction.animate(with: [
            SKTexture(imageNamed: "glow1"),
            SKTexture(imageNamed: "glow2"),
            SKTexture(imageNamed: "glow3"),
            SKTexture(imageNamed: "glow4")
        ], timePerFrame: 0.04)
        
        addChild(effect)
        effect.run(SKAction.sequence([
            animation,
            SKAction.removeFromParent()
        ]))
        
        if naturalExpiration {
            playSoundEffect(named: "shield_off.wav")
        }
    }
    
    // MARK: - Game Update
    override func update(_ currentTime: TimeInterval) {
        if isGameOver { return }
        
        if !isTouching {
            carTiltAngle = carTiltAngle > 0 ?
                max(0, carTiltAngle - tiltReturnSpeed) :
                min(0, carTiltAngle + tiltReturnSpeed)
            car.zRotation = carTiltAngle
        }
        
        if isBoosted && currentTime >= boostEndTime {
            isBoosted = false
            roadSpeed = baseRoadSpeed
        }
        
        moveRoad()
        moveObjects()
        checkBiomeChange(currentTime: currentTime)
        
        if Int.random(in: 1...100) == 1 {
            spawnPowerup()
        }
    }
    
    private func moveRoad() {
        enumerateChildNodes(withName: "road") { node, _ in
            node.position.y -= self.roadSpeed
            
            if node.position.y < -self.size.height {
                node.position.y += self.size.height * 2
                
                if let road = node as? SKSpriteNode {
                    if self.isTransitioningBiome {
                        if !self.transitionRoadPlaced {
                            let currentBiome = self.biomes[self.currentBiomeIndex]
                            let nextBiome = self.biomes[self.nextBiomeIndex]
                            
                            if let transitionTexture = currentBiome.transitionTexture(to: nextBiome) {
                                road.texture = transitionTexture
                                self.transitionRoadPlaced = true
                            } else {
                                road.texture = nextBiome.roadTexture()
                                self.completeBiomeTransition()
                            }
                        } else {
                            road.texture = self.biomes[self.nextBiomeIndex].roadTexture()
                            self.completeBiomeTransition()
                        }
                    } else {
                        road.texture = self.biomes[self.currentBiomeIndex].roadTexture()
                    }
                }
            }
        }
    }
    
    private func moveObjects() {
        let currentBiome = biomes[currentBiomeIndex]
        let isDesertBiome = currentBiome.name == "DESERT"

        enumerateChildNodes(withName: "coin") { node, _ in
            node.position.y -= self.roadSpeed
            if node.position.y < -self.coinSize.height {
                node.removeFromParent()
            }
        }
        
        enumerateChildNodes(withName: "cash") { node, _ in
            node.position.y -= self.roadSpeed
            if node.position.y < -self.coinSize.height {
                node.removeFromParent()
            }
        }
        
        enumerateChildNodes(withName: "powerup") { node, _ in
            node.position.y -= self.roadSpeed
            if node.position.y < -self.coinSize.height {
                node.removeFromParent()
            }
        }

        enumerateChildNodes(withName: "obstacle") { node, _ in
            guard let obstacle = node as? SKSpriteNode else { return }

            var speedMultiplier: CGFloat = 0.0
            var moveDirection: CGFloat = 0
            var shouldMoveWithRoad = false

            if let userData = obstacle.userData as? [String: Any] {
                if let typeValue = userData["obstacleType"] as? Int,
                   let type = ObstacleType(rawValue: typeValue) {
                    shouldMoveWithRoad = type.shouldMoveWithRoad
                }
                
                if let multiplier = userData["speedMultiplier"] as? CGFloat {
                    speedMultiplier = multiplier
                }
                
                if isDesertBiome,
                   let direction = userData["moveDirection"] as? Int {
                    moveDirection = CGFloat(direction) * 1.5
                }
            }

            if speedMultiplier > 0 {
                let verticalSpeed: CGFloat
                if shouldMoveWithRoad {
                    verticalSpeed = self.roadSpeed
                } else {
                    verticalSpeed = (self.roadSpeed + 1.5) * currentBiome.obstacleSpeed * speedMultiplier
                }
                
                node.position.y -= verticalSpeed
                
                if moveDirection != 0 {
                    node.position.x += moveDirection
                    
                    let obstacleHalfWidth = obstacle.size.width / 2
                    
                    if node.position.x + obstacleHalfWidth > self.size.width {
                        node.position.x = self.size.width - obstacleHalfWidth
                        moveDirection = -abs(moveDirection)
                        obstacle.xScale = -1
                        obstacle.userData?.setValue(-1, forKey: "moveDirection")
                    }
                    
                    else if node.position.x - obstacleHalfWidth < 0 {
                        node.position.x = obstacleHalfWidth
                        moveDirection = abs(moveDirection)
                        obstacle.xScale = 1
                        obstacle.userData?.setValue(1, forKey: "moveDirection")
                    }
                }
            } else {
                node.position.y -= self.roadSpeed
            }

            if node.position.y < -obstacle.size.height {
                node.removeFromParent()
            }
        }
    }
    
    // MARK: - Biome Management
    private func checkBiomeChange(currentTime: TimeInterval) {
        guard !isTransitioningBiome else { return }
        
        if currentTime - lastBiomeChangeTime > biomeChangeInterval {
            startBiomeTransition()
            lastBiomeChangeTime = currentTime
        }
    }
    
    private func startBiomeTransition() {
        isTransitioningBiome = true
        transitionProgress = 0.0
        transitionRoadPlaced = false
        
        removeAction(forKey: "obstacleSpawn")
        
        repeat {
            nextBiomeIndex = Int.random(in: 0..<biomes.count)
        } while nextBiomeIndex == currentBiomeIndex ||
                (biomes[currentBiomeIndex].name == "DESERT" && biomes[nextBiomeIndex].name == "WINTER") ||
                (biomes[currentBiomeIndex].name == "WINTER" && biomes[nextBiomeIndex].name == "DESERT")
    }
    
    private func completeBiomeTransition() {
        currentBiomeIndex = nextBiomeIndex
        isTransitioningBiome = false
        transitionRoadPlaced = false
        backgroundColor = biomes[currentBiomeIndex].color
        
        playBiomeMusic(biome: biomes[currentBiomeIndex])
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(spawnObstacle),
                SKAction.wait(forDuration: 1.5)
            ])
        ), withKey: "obstacleSpawn")
    }
    
    // MARK: - Game Over
    private func gameOver() {
        guard !isGameOver else { return }
        
        isGameOver = true
        removeAction(forKey: "coinSpawn")
        removeAction(forKey: "obstacleSpawn")
        removeAction(forKey: "shieldDisable")
        
        isTransitioningBiome = false
        
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "highScore")
        }
        
        playSoundEffect(named: "crash.wav")
        
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = car.position
        explosion.zPosition = 20
        addChild(explosion)
        
        showGameOverScreen()
    }
    
    private func showGameOverScreen() {
        let overlay = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.7), size: size)
        overlay.position = CGPoint(x: size.width/2, y: size.height/2)
        overlay.zPosition = 50
        addChild(overlay)
        
        let gameOverLabel = SKLabelNode(text: "GAME OVER")
        gameOverLabel.fontName = "AvenirNext-Bold"
        gameOverLabel.fontSize = 48
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: size.width/2, y: size.height/2 + 100)
        gameOverLabel.zPosition = 51
        addChild(gameOverLabel)
        
        let scoreLabel = SKLabelNode(text: "SCORE: \(score)")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width/2, y: size.height/2 + 30)
        scoreLabel.zPosition = 51
        addChild(scoreLabel)
        
        let highScoreLabel = SKLabelNode(text: "BEST: \(highScore)")
        highScoreLabel.fontName = "AvenirNext-Bold"
        highScoreLabel.fontSize = 36
        highScoreLabel.fontColor = SKColor(hex: "FFD500")
        highScoreLabel.position = CGPoint(x: size.width/2, y: size.height/2 - 20)
        highScoreLabel.zPosition = 51
        addChild(highScoreLabel)
        
        // Restart Button
        let restartButton = SKSpriteNode(color: .systemBlue, size: CGSize(width: 200, height: 60))
        restartButton.position = CGPoint(x: size.width/2, y: size.height/2 - 100)
        restartButton.zPosition = 51
        restartButton.name = "restartButton"
        addChild(restartButton)
        
        let restartLabel = SKLabelNode(text: "PLAY AGAIN")
        restartLabel.fontName = "AvenirNext-Bold"
        restartLabel.fontSize = 24
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: 0, y: -8)
        restartLabel.zPosition = 52
        restartButton.addChild(restartLabel)
        
        // Menu Button
        let menuButton = SKSpriteNode(color: .systemPurple, size: CGSize(width: 200, height: 60))
        menuButton.position = CGPoint(x: size.width/2, y: size.height/2 - 180)
        menuButton.zPosition = 51
        menuButton.name = "menuButton"
        addChild(menuButton)
        
        let menuLabel = SKLabelNode(text: "MAIN MENU")
        menuLabel.fontName = "AvenirNext-Bold"
        menuLabel.fontSize = 24
        menuLabel.fontColor = .white
        menuLabel.position = CGPoint(x: 0, y: -8)
        menuLabel.zPosition = 52
        menuButton.addChild(menuLabel)
    }
    
    private func restartGame() {
        playSoundEffect(named: "click.wav")
        let gameScene = GameScene(size: self.size)
        gameScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 0.5)
        self.view?.presentScene(gameScene, transition: transition)
    }

    private func returnToMenu() {
        playSoundEffect(named: "click.wav")
        let menuScene = MenuScene(size: self.size)
        menuScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 0.5)
        self.view?.presentScene(menuScene, transition: transition)
    }
    
    // MARK: - Effects
    private func spawnTireSmoke(reversed: Bool = true) {
        guard let smokeTemplate = SKEmitterNode(fileNamed: "TireSmoke") else { return }
        
        smokeTemplate.numParticlesToEmit = 20
        smokeTemplate.particleBirthRate = 12
        smokeTemplate.particleLifetime = 0.2
        smokeTemplate.particleLifetimeRange = 0.1
        smokeTemplate.particleSize = CGSize(width: 10, height: 10)
        smokeTemplate.particleScaleRange = 0.5
        
        let leftSmoke = smokeTemplate.copy() as! SKEmitterNode
        leftSmoke.position = CGPoint(x: car.position.x - carSize.width/5, y: car.position.y - carSize.height/2)
        leftSmoke.zPosition = 9
        leftSmoke.targetNode = self
        
        let rightSmoke = smokeTemplate.copy() as! SKEmitterNode
        rightSmoke.position = CGPoint(x: car.position.x + carSize.width/5, y: car.position.y - carSize.height/2)
        rightSmoke.zPosition = 9
        rightSmoke.targetNode = self
        
        if reversed {
            leftSmoke.emissionAngle += .pi
            rightSmoke.emissionAngle += .pi
        }
        
        addChild(leftSmoke)
        addChild(rightSmoke)
        
        let fadeAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.05),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ])
        
        leftSmoke.run(fadeAction)
        rightSmoke.run(fadeAction)
    }
    
    private func spawnCoinEffect(at position: CGPoint) {
        let coinEffect = SKSpriteNode(imageNamed: "glow1")
        coinEffect.position = position
        coinEffect.zPosition = 15
        coinEffect.setScale(0.6)
        
        let animation = SKAction.animate(with: [
            SKTexture(imageNamed: "glow1"),
            SKTexture(imageNamed: "glow2"),
            SKTexture(imageNamed: "glow3"),
            SKTexture(imageNamed: "glow4")
        ], timePerFrame: 0.04)
        
        addChild(coinEffect)
        coinEffect.run(SKAction.sequence([
            animation,
            SKAction.removeFromParent()
        ]))
    }
    
    private func spawnPowerupEffect(at position: CGPoint) {
        let effect = SKSpriteNode(imageNamed: "glow1")
        effect.position = position
        effect.zPosition = 15
        effect.setScale(0.8)
        effect.color = SKColor.blue
        effect.colorBlendFactor = 0.8
        
        let animation = SKAction.animate(with: [
            SKTexture(imageNamed: "glow1"),
            SKTexture(imageNamed: "glow2"),
            SKTexture(imageNamed: "glow3"),
            SKTexture(imageNamed: "glow4")
        ], timePerFrame: 0.04)
        
        addChild(effect)
        effect.run(SKAction.sequence([
            animation,
            SKAction.removeFromParent()
        ]))
    }
}
