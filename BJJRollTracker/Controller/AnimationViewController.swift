//
//  AnimationViewController.swift
//  BJJRollTracker
//
//  Created by Hasan Qasim on 22/9/20.
//  Copyright © 2020 Hasan Qasim. All rights reserved.
//

import UIKit
import AVFoundation

class TimerViewController: UIViewController {
        
    @IBOutlet weak var roundLabel: UILabel!
    
    let subview = UIView()
    let shapeLayer = CAShapeLayer()
    let trackLayer = CAShapeLayer()
    var textLayer: CATextLayer?
     
    var timer: Timer?
    var secondsCounter = 60
    var minutesCounter = 0
    var totalRounds = 0
    var roundCounter = 0
    
    var seshStarted = false
    
    var currentRollSetting: RollSetting?
    
    var strokeEndMultiplier: CGFloat?
    
    var audioPlayer: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .black
        
        setupAudioPlayer()
        createSubview()

        trackLayer.animate(with: UIColor.darkGray.cgColor)
        shapeLayer.animate(with: UIColor.red.cgColor)
        shapeLayer.strokeEnd = 0
        textLayer = createTextLayer(textColor: UIColor.white.cgColor)
        
        positionLayers()
        addLayersToSubview()
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "settings" {
            let settingsViewController = segue.destination as! SettingsViewController
            settingsViewController.delegate = self
        }
    }
    
    func setupAudioPlayer() {
        let sound = Bundle.main.path(forResource: "alarm", ofType: "mp3")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
        } catch {
            print(error)
        }
    }
    
}

//MARK: timer logic
extension TimerViewController {
    
    @objc func handleTap() {
        print("attempting to animate stroke")
        if timer == nil {
            if seshStarted {
                startTimer()
            }
        } else {
            print("timer already running")
            stopTimer()
        }
        
    }
    
    @objc func updateTimer() {
        if minutesCounter == currentRollSetting?.roundTime && secondsCounter == 60 && roundCounter < totalRounds {
            startNewRound()
        }
        
        minutesCounter -= secondsCounter == 60 ? 1 : 0
        secondsCounter = secondsCounter == 0 && minutesCounter != 0 ? 60 : secondsCounter
        secondsCounter -= 1
        
        if minutesCounter == 0 && secondsCounter == currentRollSetting!.warningTime {
            audioPlayer?.play()
        }
        
        textLayer?.string = (secondsCounter >= 10) ? "0\(minutesCounter):\(secondsCounter)": "0\(minutesCounter):0\(secondsCounter)"
        if let multiplier = strokeEndMultiplier {
            shapeLayer.strokeEnd += (1/75)/multiplier
        }
        
        if minutesCounter == 0 && secondsCounter == 0 {
            stopTimer()
            if roundCounter < totalRounds {
                secondsCounter = 60
                minutesCounter = currentRollSetting!.roundTime
            } else {
                seshStarted = false
            }
        }
    }
    
    func startNewRound() {
        shapeLayer.strokeEnd = 0
        roundCounter += 1
        roundLabel.text = "\(roundCounter)/\(totalRounds)"
    }
    
    func startTimer() {
        let timer = Timer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: .common)
        self.timer = timer
        print("timer started")
    }
    
    func stopTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
            print("in function: \(#function), timer stopped")
        }
    }
    
}


//MARK: delegate
extension TimerViewController: SettingsViewControllerDelegate {
    
    func didSelectRollSetting(rollSetting: RollSetting) {
        stopTimer()
        seshStarted = true
        currentRollSetting = rollSetting
        minutesCounter = currentRollSetting!.roundTime
        secondsCounter = 60
        totalRounds = currentRollSetting!.numberOfRounds
        roundCounter = 0
        strokeEndMultiplier = CGFloat(minutesCounter)
        updateUI()
        
        print("we here \(#function)")
    }
}

//MARK: AnimationViewController UI updates
extension TimerViewController {
    
    func createSubview() {
        subview.frame = CGRect(x: 0, y: 0, width: 375, height: 400)
        subview.backgroundColor = .black
        subview.center = view.center
        view.addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.widthAnchor.constraint(equalToConstant: 375).isActive = true
        subview.heightAnchor.constraint(equalToConstant: 400).isActive = true
        subview.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        subview.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    func createTextLayer(textColor: CGColor) -> CATextLayer {
        let width = view.frame.width
        let height = view.frame.height
        
        let fontSize = min(width, height) / 4
        let offset = min(width, height) * 0.1
        
        let layer = CATextLayer()
        layer.string = "00:00"
        layer.foregroundColor = textColor
        layer.fontSize = fontSize
        layer.frame = CGRect(x: 0, y: (height-fontSize-offset)/2, width: width, height: fontSize + offset)
        layer.alignmentMode = .center
        return layer
    }

    func positionLayers() {
        trackLayer.position = CGPoint(x: subview.bounds.midX, y: subview.bounds.midY)
        shapeLayer.position = CGPoint(x: subview.bounds.midX, y: subview.bounds.midY)
        textLayer!.position = CGPoint(x: subview.bounds.midX, y: subview.bounds.midY)
    }
    
    func addLayersToSubview() {
        subview.layer.addSublayer(trackLayer)
        subview.layer.addSublayer(shapeLayer)
        subview.layer.addSublayer(textLayer!)
    }
    
    func updateUI() {
        shapeLayer.strokeEnd = 0
        textLayer?.string = "0\(minutesCounter):00"
        roundLabel.text = "\(roundCounter)/\(totalRounds)"
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        //print("viewWillLayoutSubviews")
        //print(UIDevice.current.orientation.isLandscape ? "landscape":"potrait")
    }
}

// MARK: CAShapeLayer extension
extension CAShapeLayer {
    func animate(with color: CGColor) {
        let circularPath = UIBezierPath(arcCenter: .zero, radius: 175, startAngle: -CGFloat.pi/2, endAngle: 2*CGFloat.pi, clockwise: true)
        self.path = circularPath.cgPath
        self.strokeColor = color
        self.lineWidth = 10
        self.lineCap = .round
    }
}




