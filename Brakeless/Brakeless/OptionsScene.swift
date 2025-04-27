//
//  OptionsScene.swift
//  Brakeless
//
//  Created by Hubert on 27/04/2025.
//

import SpriteKit

class OptionsScene: SKScene {
    
    private var soundEffectsButton: SKSpriteNode!
    private var musicButton: SKSpriteNode!
    private var soundEffectsLabel: SKLabelNode!
    private var musicLabel: SKLabelNode!
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
        

        let background = SKSpriteNode(imageNamed: "road_pic")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -1
        background.size = self.size
        addChild(background)
        

        let titleLabel = SKLabelNode(text: "OPTIONS")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 38
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.8)
        titleLabel.zPosition = 10
        addChild(titleLabel)
        
        soundEffectsButton = SKSpriteNode(color: SKColor(hex: "FFBF00"), size: CGSize(width: 300, height: 60))
        soundEffectsButton.position = CGPoint(x: size.width / 2, y: size.height * 0.6)
        soundEffectsButton.zPosition = 10
        soundEffectsButton.name = "soundEffectsButton"
        addChild(soundEffectsButton)
        
        soundEffectsLabel = SKLabelNode(text: "SOUND EFFECTS: ON")
        soundEffectsLabel.fontName = "AvenirNext-Bold"
        soundEffectsLabel.fontSize = 24
        soundEffectsLabel.fontColor = SKColor.white
        soundEffectsLabel.position = CGPoint(x: 0, y: -8)
        soundEffectsLabel.zPosition = 11
        soundEffectsLabel.name = "soundEffectsButton"
        soundEffectsButton.addChild(soundEffectsLabel)
        
        musicButton = SKSpriteNode(color: SKColor(hex: "FFBF00"), size: CGSize(width: 300, height: 60))
        musicButton.position = CGPoint(x: size.width / 2, y: size.height * 0.5)
        musicButton.zPosition = 10
        musicButton.name = "musicButton"
        addChild(musicButton)
        
        musicLabel = SKLabelNode(text: "MUSIC: ON")
        musicLabel.fontName = "AvenirNext-Bold"
        musicLabel.fontSize = 24
        musicLabel.fontColor = SKColor.white
        musicLabel.position = CGPoint(x: 0, y: -8)
        musicLabel.zPosition = 11
        musicLabel.name = "musicButton"
        musicButton.addChild(musicLabel)
        
        let backButton = SKSpriteNode(color: SKColor(hex: "CE1D24"), size: CGSize(width: 200, height: 60))
        backButton.position = CGPoint(x: size.width / 2, y: size.height * 0.3)
        backButton.zPosition = 10
        backButton.name = "backButton"
        addChild(backButton)
        
        let backLabel = SKLabelNode(text: "BACK")
        backLabel.fontName = "AvenirNext-Bold"
        backLabel.fontSize = 24
        backLabel.fontColor = SKColor.white
        backLabel.position = CGPoint(x: 0, y: -8)
        backLabel.zPosition = 11
        backLabel.name = "backButton"
        backButton.addChild(backLabel)
        
        // Github
        let githubLink = SKLabelNode(text: "Created by Hubert Jędruchniewicz")
        githubLink.fontName = "AvenirNext-Medium"
        githubLink.fontSize = 16
        githubLink.fontColor = SKColor(white: 1.0, alpha: 0.7)
        githubLink.position = CGPoint(x: size.width / 2, y: 30)
        githubLink.zPosition = 10
        githubLink.name = "githubLink"
        addChild(githubLink)
        
        updateButtonStates()
    }
    
    private func updateButtonStates() {
        let soundEffectsDisabled = UserDefaults.standard.bool(forKey: "soundEffectsDisabled")
        soundEffectsLabel.text = "SOUND EFFECTS: \(soundEffectsDisabled ? "OFF" : "ON")"
        
        let musicDisabled = UserDefaults.standard.bool(forKey: "musicDisabled")
        musicLabel.text = "MUSIC: \(musicDisabled ? "OFF" : "ON")"
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
        
        if nodes.contains(where: { $0.name == "soundEffectsButton" }) {
            
            playSoundEffect(named: "click.wav")
            let currentState = UserDefaults.standard.bool(forKey: "soundEffectsDisabled")
            UserDefaults.standard.set(!currentState, forKey: "soundEffectsDisabled")
            updateButtonStates()
        }
        else if nodes.contains(where: { $0.name == "musicButton" }) {
            
            playSoundEffect(named: "click.wav")
            let currentState = UserDefaults.standard.bool(forKey: "musicDisabled")
            UserDefaults.standard.set(!currentState, forKey: "musicDisabled")
            updateButtonStates()
        }
        else if nodes.contains(where: { $0.name == "backButton" }) {
            
            playSoundEffect(named: "click.wav")
            let menuScene = MenuScene(size: self.size)
            menuScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 0.5)
            self.view?.presentScene(menuScene, transition: transition)
        }
        else if nodes.contains(where: { $0.name == "githubLink" }) {
            // Github
            if let url = URL(string: "https://github.com/hadoyyo") {
                UIApplication.shared.open(url)
            }
        }
    }
}

extension SKColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: 1.0
        )
    }
}
