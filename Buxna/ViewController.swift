import UIKit
import Foundation
import AudioToolbox

extension UIColor {
    static func random() -> UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
}

class CircleView: UIView {
    var outerLayer: CALayer!
    var color: UIColor!
    var ringLayer: CAShapeLayer!

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.layer.cornerRadius = frame.size.width / 2
        color = UIColor.random()
        self.layer.borderWidth = 1.0
        self.layer.borderColor = color.cgColor
        self.layer.backgroundColor = color.cgColor
        addOuterCircle()
        addRing()
        startPulsing()
        animateRing()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addOuterCircle() {
        let outerSize: CGFloat = self.bounds.size.width * 0.8 * 1.5
        outerLayer = CALayer()
        outerLayer.bounds = CGRect(x: 0, y: 0, width: outerSize, height: outerSize)
                outerLayer.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        outerLayer.cornerRadius = outerSize / 2
        outerLayer.borderWidth = 1.0
        outerLayer.borderColor = color.cgColor
        outerLayer.backgroundColor = UIColor.clear.cgColor
        self.layer.insertSublayer(outerLayer, at: 0)
    }
    
    func addRing() {
        let path = UIBezierPath()
        path.addArc(withCenter: CGPoint(x: self.bounds.midX, y: self.bounds.midY), radius: self.bounds.size.width * 0.8 * 0.75, startAngle: -.pi/2, endAngle: .pi * 2 - .pi/2, clockwise: true)
        ringLayer = CAShapeLayer()
        ringLayer.path = path.cgPath
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.strokeColor = UIColor.white.cgColor
        ringLayer.lineWidth = self.bounds.size.width * 0.8 * 0.5 / 3.0
        ringLayer.strokeEnd = 0.25
        self.layer.addSublayer(ringLayer)
    }
    
    func startPulsing() {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1
        pulseAnimation.toValue = 0.8
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = Float.greatestFiniteMagnitude
        self.layer.add(pulseAnimation, forKey: "pulse")
        outerLayer.add(pulseAnimation, forKey: "pulse")
    }
    
    func animateRing() {
        let animateStrokeEnd = CABasicAnimation(keyPath: "strokeEnd")
        animateStrokeEnd.fromValue = 0.25
        animateStrokeEnd.toValue = 1.0
        animateStrokeEnd.duration = 1.25
        animateStrokeEnd.fillMode = .forwards
        animateStrokeEnd.isRemovedOnCompletion = false
        ringLayer.add(animateStrokeEnd, forKey: "animate stroke end animation")
    }
}

class ViewController: UIViewController {
    
    
    var welcomeMessageLabel: UILabel!
    // Variable to decide whether to ignore touches or not
    var ignoreTouches = false
    var numberOfWinners = 1
    var winnerSelectionButton: UIButton!
    var maxFingersLabel: UILabel!

    func setupMaxFingersLabel() {
        maxFingersLabel = UILabel()
        maxFingersLabel.translatesAutoresizingMaskIntoConstraints = false
        maxFingersLabel.text = "Maximum of 5 Fingers at a Time on iPhones."
        maxFingersLabel.textAlignment = .center
        maxFingersLabel.textColor = .systemBlue
        self.view.addSubview(maxFingersLabel)
        
        NSLayoutConstraint.activate([
            maxFingersLabel.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            maxFingersLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            maxFingersLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }

    
    func setupWinnerSelectionButton() {
        winnerSelectionButton = UIButton(type: .system)
        winnerSelectionButton.translatesAutoresizingMaskIntoConstraints = false
        winnerSelectionButton.setTitle("Winners: 1", for: .normal)
        winnerSelectionButton.setTitleColor(UIColor.systemBlue, for: .normal)
        winnerSelectionButton.addTarget(self, action: #selector(showWinnerSelectionAlert), for: .touchUpInside)
        self.view.addSubview(winnerSelectionButton)

        NSLayoutConstraint.activate([
            winnerSelectionButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: self.view.bounds.size.height * 0.015),
            winnerSelectionButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }

    @objc func showWinnerSelectionAlert() {
        let alertController = UIAlertController(title: "Select Number of Winners", message: nil, preferredStyle: .actionSheet)
        for i in 1...4 {
            alertController.addAction(UIAlertAction(title: "\(i)", style: .default) { _ in
                self.numberOfWinners = i
                self.winnerSelectionButton.setTitle("Winners: \(i)", for: .normal)
            })
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }


    
    struct TouchData {
        let touch: UITouch
        let circle: CircleView
    }
    
    var circleCount = 0
    var groupModeEnabled = false
    var groupColors: [UIColor] = [.random(), .random()]
    
    var originalBackgroundColor: UIColor?
    var touchesData = [TouchData]()
    var winnerSelectionTimer: Timer?
    
    lazy var groupModeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Switch to Group Mode", for: .normal)
        button.addTarget(self, action: #selector(toggleGroupMode), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Enable multiple touch handling for the view
        self.view.isMultipleTouchEnabled = true
        // Store the original background color of the view
        self.originalBackgroundColor = self.view.backgroundColor
        // Set up UI elements
        setupGroupModeButton()
        setupWinnerSelectionButton()
        setupWelcomeMessage()
        setupMaxFingersLabel()
    }
    
    func setupWelcomeMessage() {
        // Create a UILabel for the welcome message
        welcomeMessageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 100))
        welcomeMessageLabel.center = self.view.center
        welcomeMessageLabel.text = "Welcome to Buxna - Finger Chooser! \n\n Designed by Adam Burmuzoski"
        welcomeMessageLabel.numberOfLines = 0
        welcomeMessageLabel.textColor = UIColor(red: 252.0/255.0, green: 69.0/255.0, blue: 3.0/255.0, alpha: 1.0) // #fc4503
        welcomeMessageLabel.textAlignment = .center
        // Add the welcome message label to the view
        self.view.addSubview(welcomeMessageLabel)
    }


    
    func setupGroupModeButton() {
        // Create a UIButton for the group mode button
        groupModeButton = UIButton(type: .system)
        groupModeButton.translatesAutoresizingMaskIntoConstraints = false
        groupModeButton.setTitle("Switch to Group Mode", for: .normal)
        groupModeButton.setTitleColor(UIColor.systemBlue, for: .normal)
        groupModeButton.addTarget(self, action: #selector(toggleGroupMode), for: .touchUpInside)
        // Add the group mode button to the view
        self.view.addSubview(groupModeButton)
        // Set up layout constraints for the group mode button
        NSLayoutConstraint.activate([
            groupModeButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: self.view.bounds.size.height * 0.015),
            groupModeButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 20)
        ])
    }
    
    @objc func toggleGroupMode() {
        if groupModeEnabled {
                groupModeButton.setTitle("Single Mode", for: .normal)
                winnerSelectionButton.isHidden = false // This line makes the button visible in Single Mode.
            } else {
                groupModeButton.setTitle("Group Mode", for: .normal)
                winnerSelectionButton.isHidden = true // This line makes the button hidden in Group Mode.
            }
            groupModeEnabled.toggle()
        groupModeButton.setTitle(groupModeEnabled ? "Switch to Single Mode" : "Switch to Group Mode", for: .normal)
        if groupModeEnabled {
            groupColors = [.random(), .random()]
        }
    }
    
    // This method is called when a touch on the view begins. It creates a new CircleView at the touch location and adds it to an array of active touches. The CircleView is also added as a subview of the main view. A Boolean flag is checked to ensure that only 5 simultaneous touches are registered.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)

            if ignoreTouches {
                return
            }
            // Get the count of new touches
            let newTouchesCount = touches.filter { $0.phase == .began }.count

            // Check if the total number of touches exceeds the limit
            if touchesData.count + newTouchesCount > 5 {
                // If so, animate and remove all existing circles
                for touchData in touchesData {
                    UIView.animate(withDuration: 0.5, animations: {
                        touchData.circle.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                        touchData.circle.alpha = 0
                    }) { _ in
                        touchData.circle.removeFromSuperview()
                    }
                }
                // Clear the touchesData
                touchesData.removeAll()
                ignoreTouches = true
                return
            }
        for touch in touches {
            let location = touch.location(in: self.view)
            let circle = createCircle(at: location)
            self.view.addSubview(circle)
            touchesData.append(TouchData(touch: touch, circle: circle))
        }
        
        resetTimer()
        
        // Hide the labels when a touch event begins.
        welcomeMessageLabel.isHidden = true
        maxFingersLabel.isHidden = true
    }
    
    // This method is called when a finger already in contact with the screen moves. It updates the position of the corresponding CircleView to the new touch location.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let touchData = touchesData.first(where: {$0.touch == touch}) {
                touchData.circle.center = touch.location(in: self.view)
            }
        }
    }
    
    // These methods are called when a touch ends, either naturally (the finger is lifted from the screen) or because of some interruption (for instance, a phone call). The methods remove the corresponding CircleView with a fading "pulse out" animation and also remove the touch from the array of active touches. If the Boolean flag was set because the maximum number of simultaneous touches was exceeded, it's reset if the number of active touches drops below 5.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        if ignoreTouches && touchesData.count < 5 {
            ignoreTouches = false
        }

        for touch in touches {
            if let touchData = touchesData.first(where: {$0.touch == touch}) {
                touchData.circle.removeFromSuperview()
                if let index = touchesData.firstIndex(where: {$0.touch == touch}) {
                    touchesData.remove(at: index)
                }
            }
        }
        
        if touchesData.count < 2 {
            winnerSelectionTimer?.invalidate()
            winnerSelectionTimer = nil
        } else if !groupModeEnabled {
            resetTimer()
        }
        
        if touchesData.count == 0 && !groupModeEnabled {
            // Reset game mode
            groupModeButton.setTitle("Switch to Group Mode", for: .normal)
            winnerSelectionButton.isHidden = false
        }
    }
    
    // Dissappears the circles if over 5 are detected.
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        // Reset the ignoreTouches flag if there are fewer than 5 touch data
        if ignoreTouches && touchesData.count < 5 {
            ignoreTouches = false
        }
        
        // Handle each cancelled touch
        for touch in touches {
            if let touchData = touchesData.first(where: {$0.touch == touch}) {
                UIView.animate(withDuration: 0.5, animations: {
                    touchData.circle.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                    touchData.circle.alpha = 0
                }, completion: { _ in
                    touchData.circle.removeFromSuperview()
                })
                // Remove the touch data from the array
                if let index = touchesData.firstIndex(where: {$0.touch == touch}) {
                    touchesData.remove(at: index)
                }
            }
        }
        // Check the remaining number of touch data and update timer or game mode
        if touchesData.count < 2 {
            // Invalidate the timer if there are fewer than 2 touch data
            winnerSelectionTimer?.invalidate()
            winnerSelectionTimer = nil
        } else if !groupModeEnabled {
            // Reset the timer if in normal mode and there are still enough touch data
            resetTimer()
        }
        
        if touchesData.count == 0 {
            // Reset game mode if there are no remaining touch data
            groupModeButton.setTitle("Switch to Group Mode", for: .normal)
            winnerSelectionButton.isHidden = false
            groupModeEnabled = false
        }
    }

    func resetTimer() {
        // Invalidate the previous timer (if any)
        winnerSelectionTimer?.invalidate()
        // Schedule a new timer that calls the `selectWinner` method after 1.75 seconds
        winnerSelectionTimer = Timer.scheduledTimer(timeInterval: 1.75, target: self, selector: #selector(selectWinner), userInfo: nil, repeats: false)
    }

    @objc func selectWinner() {
        if groupModeEnabled {
            // Generate two random colors for the two teams
            let teamColors = [UIColor.random(), UIColor.random()]

            // In group mode, we distribute colors and then stop the timer
            for (index, touchData) in touchesData.enumerated() {
                let color = teamColors[index % 2]
                touchData.circle.color = color
                touchData.circle.layer.borderColor = color.cgColor
                touchData.circle.layer.backgroundColor = color.cgColor
                touchData.circle.outerLayer.borderColor = color.cgColor
            }
            
            // Vibrate the device after changing the colors
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)

            // Invalidate timer so that colors don't keep changing
            winnerSelectionTimer?.invalidate()
            winnerSelectionTimer = nil
        } else {
            // Single Mode
            if touchesData.count > numberOfWinners {
                var winners: [TouchData] = []
                for _ in 0..<numberOfWinners {
                    let winnerIndex = Int.random(in: 0..<touchesData.count)
                    let winner = touchesData.remove(at: winnerIndex)
                    winners.append(winner)
                }
                // Remove non-winners from the view
                for touchData in touchesData {
                    touchData.circle.removeFromSuperview()
                }
                touchesData = winners
                // Vibrate the device
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                // If only one winner, fill the screen with their color except their circle
                if numberOfWinners == 1 {
                    if let winner = winners.first {
                        fillScreen(withColor: winner.circle.color, exceptCircleAt: winner.circle.center, diameter: winner.circle.bounds.size.width * 2)
                    }
                }
            }
        }
    }

    func fillScreen(withColor color: UIColor, exceptCircleAt center: CGPoint, diameter: CGFloat) {
        // Create a colored layer that covers the entire screen
        let screenRect = UIScreen.main.bounds
        let coloredLayer = CALayer()
        coloredLayer.backgroundColor = color.cgColor
        coloredLayer.frame = screenRect
        coloredLayer.opacity = 0
        
        // Create a mask layer to exclude the circle at the specified center
        let maskLayer = CAShapeLayer()
        let outerPath = UIBezierPath(rect: screenRect)
        let innerCirclePath = UIBezierPath(ovalIn: CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter))
        outerPath.append(innerCirclePath)
        maskLayer.fillRule = .evenOdd
        maskLayer.path = outerPath.cgPath
        
        // Apply the mask to the colored layer
        coloredLayer.mask = maskLayer
        self.view.layer.addSublayer(coloredLayer)

        // Animate the colored layer to fade in and out
        let fadeIn = CABasicAnimation(keyPath: "opacity")
        fadeIn.fromValue = 0
        fadeIn.toValue = 1
        fadeIn.duration = 0.5

        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = 1
        fadeOut.toValue = 0
        fadeOut.beginTime = 0.5
        fadeOut.duration = 0.5

        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [fadeIn, fadeOut]
        animationGroup.duration = 1.0
        animationGroup.fillMode = .forwards
        animationGroup.isRemovedOnCompletion = false

        // Add the animation to the colored layer
        coloredLayer.add(animationGroup, forKey: "fadeInOut")

        // Remove the colored layer after the animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            coloredLayer.removeFromSuperlayer()
        }
    }

    func createCircle(at location: CGPoint) -> CircleView {
        // Create a CircleView with a default size and position at the given location
        let circle = CircleView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        circle.center = location
        
        // Set the initial color and border properties based on whether group mode is enabled or not
        if groupModeEnabled {
            circle.color = .gray
            circle.layer.borderColor = UIColor.gray.cgColor
            circle.layer.backgroundColor = UIColor.gray.cgColor
            circle.outerLayer.borderColor = UIColor.gray.cgColor
        }
        return circle
    }
}
