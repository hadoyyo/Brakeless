//
//  ShopScene.swift
//  Brakeless
//
//  Created by Hubert on 20/04/2025.
//

import SpriteKit

class ShopScene: SKScene {
    
    private var totalCoins = UserDefaults.standard.integer(forKey: "totalCoins")
    private var selectedCar = UserDefaults.standard.string(forKey: "selectedCar") ?? "car"
    
    private let availableCars: [(name: String, price: Int)] = [
        ("car", 0), ("car2", 200), ("car3", 400),
        ("car4", 600), ("car5", 800), ("car6", 1000),
        ("car7", 1200), ("car8", 1400), ("car9", 1600),
        ("car10", 1800), ("car11", 2000), ("car12", 2200)
    ]
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
        setupBackground()
        setupUI()
        setupCarGrid()
    }
    
    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: "shop_road")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -1
        background.size = self.size
        addChild(background)
    }
    
    private func setupUI() {
        // Title
        let titleLabel = SKLabelNode(text: "CAR SHOP")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 38
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.86)
        titleLabel.zPosition = 10
        addChild(titleLabel)
        
        let coinIcon = SKSpriteNode(imageNamed: "coin")
        coinIcon.size = CGSize(width: 25, height: 25)
        coinIcon.position = CGPoint(x: size.width - 45, y: size.height - 60)
        coinIcon.zPosition = 10
        addChild(coinIcon)
        
        let coinsLabel = SKLabelNode(text: "\(totalCoins)")
        coinsLabel.fontName = "AvenirNext-Bold"
        coinsLabel.fontSize = 25
        coinsLabel.fontColor = .white
        coinsLabel.horizontalAlignmentMode = .right
        coinsLabel.position = CGPoint(x: size.width - 60, y: size.height - 70)
        coinsLabel.zPosition = 10
        addChild(coinsLabel)
        
        let backButton = SKSpriteNode(color: SKColor(hex: "CE1D24"), size: CGSize(width: 100, height: 40))
        backButton.position = CGPoint(x: 70, y: size.height - 60)
        backButton.zPosition = 10
        backButton.name = "backButton"
        addChild(backButton)
        
        let backLabel = SKLabelNode(text: "BACK")
        backLabel.fontName = "AvenirNext-Bold"
        backLabel.fontSize = 18
        backLabel.fontColor = SKColor.white
        backLabel.position = CGPoint(x: 0, y: -8)
        backLabel.zPosition = 11
        backLabel.name = "backButton"
        backButton.addChild(backLabel)
    }
    
    private func setupCarGrid() {
        let columns = 3
        let rows = 4
        let margin: CGFloat = 15
        let horizontalSpacing: CGFloat = 10
        let verticalSpacing: CGFloat = 15
        
        let gridStartY = size.height * 0.75
        let gridEndY = size.height * 0.05
        let availableHeight = gridStartY - gridEndY
        
        let itemWidth = (size.width - margin * 2 - horizontalSpacing * CGFloat(columns - 1)) / CGFloat(columns)
        let itemHeight = (availableHeight - verticalSpacing * CGFloat(rows - 1)) / CGFloat(rows)
        
        let carWidth = itemWidth * 0.7 * 0.9
        let carHeight = carWidth * (80/50) * 0.92
        
        for i in 0..<availableCars.count {
            let row = i / columns
            let column = i % columns
            
            let xPos = margin + itemWidth / 2 + CGFloat(column) * (itemWidth + horizontalSpacing)
            let yPos = gridStartY - itemHeight / 2 - CGFloat(row) * (itemHeight + verticalSpacing)
            
            // Car image
            let carImage = SKSpriteNode(imageNamed: availableCars[i].name)
            carImage.size = CGSize(width: carWidth, height: carHeight)
            carImage.position = CGPoint(x: xPos, y: yPos + 10)
            carImage.zPosition = 11
            carImage.name = "car_\(availableCars[i].name)"
            addChild(carImage)
            
            // Label
            let labelPosition = CGPoint(x: xPos, y: yPos - carHeight/2 - 5)
            
            if availableCars[i].price == 0 || UserDefaults.standard.bool(forKey: "car_\(availableCars[i].name)_unlocked") {
                let ownedLabel = SKLabelNode(text: selectedCar == availableCars[i].name ? "SELECTED" : "OWNED")
                ownedLabel.fontName = "AvenirNext-Bold"
                ownedLabel.fontSize = 14
                ownedLabel.fontColor = selectedCar == availableCars[i].name ? .green : .white
                ownedLabel.position = labelPosition
                ownedLabel.zPosition = 11
                addChild(ownedLabel)
            } else {
                let priceContainer = SKNode()
                priceContainer.position = labelPosition
                priceContainer.zPosition = 11
                addChild(priceContainer)
                
                let priceLabel = SKLabelNode(text: "\(availableCars[i].price)")
                priceLabel.fontName = "AvenirNext-Bold"
                priceLabel.fontSize = 16
                priceLabel.fontColor = .white
                priceLabel.horizontalAlignmentMode = .right
                priceLabel.position = CGPoint(x: 7, y: -4)
                priceContainer.addChild(priceLabel)
                
                let coinIcon = SKSpriteNode(imageNamed: "coin")
                coinIcon.size = CGSize(width: 14, height: 14)
                coinIcon.position = CGPoint(x: 18, y: 2)
                coinIcon.zPosition = 12
                priceContainer.addChild(coinIcon)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)
        
        if nodes.contains(where: { $0.name == "backButton" }) {
            playSoundEffect(named: "click.wav")
            let menuScene = MenuScene(size: self.size)
            menuScene.scaleMode = .aspectFill
            self.view?.presentScene(menuScene, transition: .fade(withDuration: 0.5))
            return
        }
        
        for node in nodes {
            if let name = node.name, name.hasPrefix("car_") {
                handleCarSelection(carName: String(name.dropFirst(4)))
                return
            }
        }
    }
    
    private func handleCarSelection(carName: String) {
        guard let carInfo = availableCars.first(where: { $0.name == carName }) else { return }
        
        if carInfo.price == 0 || UserDefaults.standard.bool(forKey: "car_\(carName)_unlocked") {
            playSoundEffect(named: "click.wav")
            UserDefaults.standard.set(carName, forKey: "selectedCar")
            run(.sequence([
                .wait(forDuration: 0.1),
                .run { self.refreshScene() }
            ]))
        } else if totalCoins >= carInfo.price {
            playSoundEffect(named: "buy.wav")
            totalCoins -= carInfo.price
            UserDefaults.standard.set(totalCoins, forKey: "totalCoins")
            UserDefaults.standard.set(true, forKey: "car_\(carName)_unlocked")
            UserDefaults.standard.set(carName, forKey: "selectedCar")
            run(.sequence([
                .wait(forDuration: 0.3),
                .run { self.refreshScene() }
            ]))
        } else {
            playSoundEffect(named: "not_enough_money.wav")
            showNotEnoughCoins()
        }
    }
    
    private func playSoundEffect(named fileName: String) {
        if UserDefaults.standard.bool(forKey: "soundEffectsDisabled") {
            return
        }
        let playAction = SKAction.playSoundFileNamed(fileName, waitForCompletion: false)
        run(playAction)
    }
    
    private func refreshScene() {
        let shopScene = ShopScene(size: self.size)
        shopScene.scaleMode = .aspectFill
        self.view?.presentScene(shopScene)
    }
    
    private func showNotEnoughCoins() {
        let message = SKLabelNode(text: "NOT ENOUGH COINS!")
        message.fontName = "AvenirNext-Bold"
        message.fontSize = 24
        message.fontColor = .red
        message.position = CGPoint(x: size.width / 2, y: size.height * 0.8)
        message.zPosition = 20
        addChild(message)
        
        message.run(.sequence([
            .wait(forDuration: 0.5),
            .fadeOut(withDuration: 1.0),
            .removeFromParent()
        ]))
    }
}
