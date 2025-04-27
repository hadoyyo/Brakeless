//
//  MenuScene.swift
//  Cars
//
//  Created by Hubert on 23/04/2025.
//

import SpriteKit

class MenuScene: SKScene {
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
        
        let background = SKSpriteNode(imageNamed: "road_pic")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -1
        background.size = self.size
        addChild(background)
        
        let logo = SKSpriteNode(imageNamed: "logo")
        logo.position = CGPoint(x: size.width / 2, y: size.height * 0.8)
        logo.zPosition = 10
        logo.setScale(0.32)
        addChild(logo)
        
        let playButton = SKSpriteNode(color: SKColor(hex: "FFBF00"), size: CGSize(width: 200, height: 60))
        playButton.position = CGPoint(x: size.width / 2, y: size.height * 0.5)
        playButton.zPosition = 10
        playButton.name = "playButton"
        addChild(playButton)
        
        let playLabel = SKLabelNode(text: "PLAY")
        playLabel.fontName = "AvenirNext-Bold"
        playLabel.fontSize = 30
        playLabel.fontColor = SKColor.white
        playLabel.position = CGPoint(x: 0, y: -10)
        playLabel.zPosition = 11
        playLabel.name = "playButton"
        playButton.addChild(playLabel)
        
        let shopButton = SKSpriteNode(color: SKColor(hex: "CE1D24"), size: CGSize(width: 200, height: 60))
        shopButton.position = CGPoint(x: size.width / 2, y: size.height * 0.4)
        shopButton.zPosition = 10
        shopButton.name = "shopButton"
        addChild(shopButton)
        
        let shopLabel = SKLabelNode(text: "SHOP")
        shopLabel.fontName = "AvenirNext-Bold"
        shopLabel.fontSize = 30
        shopLabel.fontColor = SKColor.white
        shopLabel.position = CGPoint(x: 0, y: -10)
        shopLabel.zPosition = 11
        shopLabel.name = "shopButton"
        shopButton.addChild(shopLabel)
        
        let optionsButton = SKSpriteNode(color: SKColor(hex: "CE1D24"), size: CGSize(width: 200, height: 60))
        optionsButton.position = CGPoint(x: size.width / 2, y: size.height * 0.3)
        optionsButton.zPosition = 10
        optionsButton.name = "optionsButton"
        addChild(optionsButton)
        
        let optionsLabel = SKLabelNode(text: "OPTIONS")
        optionsLabel.fontName = "AvenirNext-Bold"
        optionsLabel.fontSize = 30
        optionsLabel.fontColor = SKColor.white
        optionsLabel.position = CGPoint(x: 0, y: -10)
        optionsLabel.zPosition = 11
        optionsLabel.name = "optionsButton"
        optionsButton.addChild(optionsLabel)
        
        let scaleUp = SKAction.scale(to: 0.32, duration: 0.5)
        let scaleDown = SKAction.scale(to: 0.3, duration: 0.5)
        let pulseSequence = SKAction.sequence([scaleUp, scaleDown])
        
        logo.run(SKAction.repeatForever(pulseSequence))
    }
    
    private func playSoundEffect(named fileName: String) {
        
        if !UserDefaults.standard.bool(forKey: "soundEffectsDisabled") {
            let adjustedVolume: Float = 0
            let playAction = SKAction.playSoundFileNamed(fileName, waitForCompletion: false)
            let volumeAction = SKAction.changeVolume(to: adjustedVolume, duration: 0.1)
            run(SKAction.group([playAction, volumeAction]))
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)
        
        if nodes.contains(where: { $0.name == "playButton" }) {

            playSoundEffect(named: "click.wav")
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 0.5)
            self.view?.presentScene(gameScene, transition: transition)
        }
        else if nodes.contains(where: { $0.name == "shopButton" }) {

            playSoundEffect(named: "click.wav")
            let shopScene = ShopScene(size: self.size)
            shopScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 0.5)
            self.view?.presentScene(shopScene, transition: transition)
        }
        else if nodes.contains(where: { $0.name == "optionsButton" }) {

            playSoundEffect(named: "click.wav")
            let optionsScene = OptionsScene(size: self.size)
            optionsScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 0.5)
            self.view?.presentScene(optionsScene, transition: transition)
        }
    }
}
