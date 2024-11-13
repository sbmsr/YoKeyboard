import UIKit

class KeyboardViewController: UIInputViewController {
    private var keys = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"],
        ["spacebar"]
    ]
    
    enum State {
        case `default`
        case morph
        case learn
    }
    
    struct TapRecord {
        let letter: String
        let position: CGPoint
        let iteration: Int
    }
    
    private let trainingPhrase = "the quick brown fox jumped over the lazy dog"
    private var currentPhraseIndex = 0
    private var currentIteration = 1
    private let totalIterations = 3
    private var tapRecords: [Character: [TapRecord]] = [:]
    private var tapGesture: UITapGestureRecognizer?
    private var learnModeView: UIView?
    
    
    private var keyboard: UIStackView!
    private var morphButton: UIButton!
    private var learnButton: UIButton!
    private var targetLetterLabel: UILabel!
    
    private var state: State = .default
    private var isMorphModeEnabled = false
    
    private var isTransitioning = false
    private var transitionLabel: UILabel!
    private var continueButton: UIButton!
    
    private var learnViewHeight: CGFloat = 180
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupTransitionViews()
    }
    
    private func setupViews() {
        // Create all UI elements first
        morphButton = UIButton(type: .system)
        morphButton.setTitle("Morph", for: .normal)
        morphButton.addTarget(self, action: #selector(toggleMorphMode), for: .touchUpInside)
        morphButton.translatesAutoresizingMaskIntoConstraints = false
        
        learnButton = UIButton(type: .system)
        learnButton.setTitle("Learn", for: .normal)
        learnButton.addTarget(self, action: #selector(toggleLearnMode), for: .touchUpInside)
        learnButton.translatesAutoresizingMaskIntoConstraints = false
        
        targetLetterLabel = UILabel()
        targetLetterLabel.font = .systemFont(ofSize: 36, weight: .bold)
        targetLetterLabel.textAlignment = .center
        targetLetterLabel.isHidden = true
        targetLetterLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let keyboardStackView = UIStackView()
        keyboardStackView.axis = .vertical
        keyboardStackView.alignment = .fill
        keyboardStackView.distribution = .fillEqually
        keyboardStackView.spacing = 4
        keyboardStackView.translatesAutoresizingMaskIntoConstraints = false
        keyboard = keyboardStackView
        
        // Add all views to hierarchy
        view.addSubview(keyboard)
        view.addSubview(morphButton)
        view.addSubview(learnButton)
        view.addSubview(targetLetterLabel)
        
        // Setup keyboard rows and keys
        for row in keys {
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.alignment = .fill
            rowStackView.distribution = .fillEqually // or .fillProportionally depending on your needs
            rowStackView.spacing = 4
            
            for k in row {
                let key = UIButton(type: .system)
                key.setTitle(k, for: .normal)
                key.titleLabel?.font = UIFont.systemFont(ofSize: 24)
                key.layer.borderWidth = 2
                key.layer.borderColor = UIColor.white.cgColor
                key.layer.cornerRadius = 5
                key.setTitleColor(UIColor.black, for: .normal)
                key.backgroundColor = UIColor.white
                key.addTarget(self, action: #selector(keyTapped(_:event:)), for: .touchUpInside)
                key.setContentHuggingPriority(.defaultLow, for: .vertical) // Add this
                key.setContentCompressionResistancePriority(.defaultLow, for: .vertical) // Add this
                rowStackView.addArrangedSubview(key)
            }
            keyboard.addArrangedSubview(rowStackView)
        }
        
        // Setup all constraints together
        NSLayoutConstraint.activate([
            // Keyboard constraints
            keyboard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            keyboard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            keyboard.topAnchor.constraint(equalTo: targetLetterLabel.bottomAnchor, constant: 8),
            keyboard.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            keyboard.heightAnchor.constraint(equalToConstant: learnViewHeight),  // Add fixed height constraint
            
            // Button and label constraints
            morphButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            morphButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),  // Anchor to top
            morphButton.heightAnchor.constraint(equalToConstant: 30),
            
            learnButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            learnButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),  // Anchor to top
            learnButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Target letter label constraints
            targetLetterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            targetLetterLabel.centerYAnchor.constraint(equalTo: morphButton.centerYAnchor),
            targetLetterLabel.heightAnchor.constraint(equalToConstant: 44)
        ])
        
    }
    
    private func setupTransitionViews() {
        transitionLabel = UILabel()
        transitionLabel.font = .systemFont(ofSize: 24, weight: .medium)
        transitionLabel.textAlignment = .center
        transitionLabel.textColor = .systemBlue
        transitionLabel.isHidden = true
        transitionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        continueButton = UIButton(type: .system)
        continueButton.setTitle("Tap to continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 20)
        continueButton.addTarget(self, action: #selector(handleContinue), for: .touchUpInside)
        continueButton.isHidden = true
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(transitionLabel)
        view.addSubview(continueButton)
        
        NSLayoutConstraint.activate([
            transitionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            transitionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.topAnchor.constraint(equalTo: transitionLabel.bottomAnchor, constant: 20)
        ])
    }
    
    
    
    private func setupKeyboard() {
        let keyboardStackView = UIStackView()
        keyboardStackView.axis = .vertical
        keyboardStackView.alignment = .fill
        keyboardStackView.distribution = .fillEqually
        keyboardStackView.spacing = 4
        keyboardStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // ... rest of keyboard setup remains the same ...
        
        view.addSubview(keyboardStackView)
        
        // Update keyboard constraints to position it below the labels
        NSLayoutConstraint.activate([
            keyboardStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            keyboardStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            keyboardStackView.topAnchor.constraint(equalTo: targetLetterLabel.bottomAnchor, constant: 20), // Position relative to label
            keyboardStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10) // Add bottom constraint
        ])
        
        keyboard = keyboardStackView
    }
    
    private func setupTargetLetterLabel() {
        targetLetterLabel = UILabel()
        targetLetterLabel.font = .systemFont(ofSize: 36, weight: .bold)
        targetLetterLabel.textAlignment = .center
        targetLetterLabel.isHidden = true
        targetLetterLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(targetLetterLabel)
        
        NSLayoutConstraint.activate([
            targetLetterLabel.topAnchor.constraint(equalTo: learnButton.bottomAnchor, constant: 10),
            targetLetterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            targetLetterLabel.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupMorphButton() {
        morphButton = UIButton(type: .system)
        morphButton.setTitle("Morph", for: .normal)  // Shortened text
        morphButton.addTarget(self, action: #selector(toggleMorphMode), for: .touchUpInside)
        morphButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(morphButton)
        
        NSLayoutConstraint.activate([
            morphButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            morphButton.bottomAnchor.constraint(equalTo: keyboard.topAnchor, constant: -5),
            morphButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupLearnButton() {
        learnButton = UIButton(type: .system)
        learnButton.setTitle("Learn", for: .normal)  // Shortened text
        learnButton.addTarget(self, action: #selector(toggleLearnMode), for: .touchUpInside)
        learnButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(learnButton)
        
        NSLayoutConstraint.activate([
            learnButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            learnButton.bottomAnchor.constraint(equalTo: keyboard.topAnchor, constant: -5),
            learnButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc private func toggleMorphMode() {
        isMorphModeEnabled.toggle()
        state = isMorphModeEnabled ? .morph : .default
        
        let title = isMorphModeEnabled ? "Stop" : "Morph"  // Shortened toggle text
        morphButton.setTitle(title, for: .normal)
    }
    
    // Update toggleLearnMode to handle phrase progression
    @objc private func toggleLearnMode() {
        switch state {
        case .default:
            state = .learn
            isTransitioning = false
            isMorphModeEnabled = false
            morphButton.isEnabled = false
            learnButton.setTitle("Stop", for: .normal)
            targetLetterLabel.isHidden = false
            currentPhraseIndex = 0
            currentIteration = 1
            tapRecords.removeAll()
            updateTargetLetter()
            
            // Remove existing learn mode view if it exists
            learnModeView?.removeFromSuperview()
            learnModeView = nil
            
            // Create and add a new blank view over the keyboard
            learnModeView = UIView()
            learnModeView?.backgroundColor = .darkGray
            if let learnView = learnModeView {
                keyboard.addSubview(learnView)
                learnView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    learnView.topAnchor.constraint(equalTo: keyboard.topAnchor),
                    learnView.bottomAnchor.constraint(equalTo: keyboard.bottomAnchor),
                    learnView.leadingAnchor.constraint(equalTo: keyboard.leadingAnchor),
                    learnView.trailingAnchor.constraint(equalTo: keyboard.trailingAnchor)
                ])
                
                // Remove any existing gesture recognizer
                if let existingGesture = tapGesture {
                    learnView.removeGestureRecognizer(existingGesture)
                }
                
                // Add new tap gesture to the blank view
                tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleLearnModeTap(_:)))
                if let gesture = tapGesture {
                    learnView.addGestureRecognizer(gesture)
                    learnView.isUserInteractionEnabled = true
                }
                
                // Ensure the learn view is on top
                keyboard.bringSubviewToFront(learnView)
            }
            
            // Hide the keyboard buttons
            keyboard.arrangedSubviews.forEach { rowView in
                guard let row = rowView as? UIStackView else { return }
                row.arrangedSubviews.forEach { button in
                    button.isHidden = true
                }
            }
            
        case .learn:
            cleanupLearnMode()
            
        case .morph:
            return
        }
        
    }
    
    private func cleanupLearnMode() {
        state = .default
        isTransitioning = false  // Add this line
        morphButton.isEnabled = true
        learnButton.setTitle("Learn", for: .normal)
        targetLetterLabel.isHidden = true
        
        // Clean up learn mode view and gesture recognizer
        if let learnView = learnModeView {
            if let gesture = tapGesture {
                learnView.removeGestureRecognizer(gesture)
            }
            learnView.removeFromSuperview()
        }
        learnModeView = nil
        tapGesture = nil
        
        // Show the keyboard buttons
        keyboard.arrangedSubviews.forEach { rowView in
            guard let row = rowView as? UIStackView else { return }
            row.arrangedSubviews.forEach { button in
                button.isHidden = false
            }
        }
        
        // If we completed all iterations, generate the layout
        if currentIteration > totalIterations {
            generateKeyboardLayout()
        }
    }
    
    @objc private func handleLearnModeTap(_ gesture: UITapGestureRecognizer) {
        guard state == .learn, !isTransitioning else { return }
        
        let location = gesture.location(in: keyboard)
        print("Learn mode tap received at: \(location)") // Debug log
        recordTapAndAdvance(at: location)
    }
    
    
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: keyboard)
        recordTapAndAdvance(at: location)
    }
    
    private func updateTargetLetter() {
        if currentPhraseIndex < trainingPhrase.count {
            let index = trainingPhrase.index(trainingPhrase.startIndex, offsetBy: currentPhraseIndex)
            targetLetterLabel.text = String(trainingPhrase[index])
        }
    }
    
    private func recordTapAndAdvance(at position: CGPoint) {
        guard currentPhraseIndex < trainingPhrase.count, !isTransitioning else { return }
        
        let index = trainingPhrase.index(trainingPhrase.startIndex, offsetBy: currentPhraseIndex)
        let letter = trainingPhrase[index]
        
        // Record the tap
        let record = TapRecord(letter: String(letter), position: position, iteration: currentIteration)
        if tapRecords[letter] == nil {
            tapRecords[letter] = []
        }
        tapRecords[letter]?.append(record)
        
        // Advance to next letter
        currentPhraseIndex += 1
        
        // Check if we completed the phrase
        if currentPhraseIndex >= trainingPhrase.count {
            showTransition()
        } else {
            updateTargetLetter()
        }
    }
    
    private func showTransition() {
        isTransitioning = true
        
        // Hide keyboard interaction view and target letter
        learnModeView?.isHidden = true
        targetLetterLabel.isHidden = true
        
        // Show transition UI
        transitionLabel.text = "Iteration \(currentIteration) complete!\nStarting iteration \(currentIteration + 1) of \(totalIterations)"
        transitionLabel.isHidden = false
        continueButton.isHidden = false
        
        // Animate the transition UI
        transitionLabel.alpha = 0
        continueButton.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.transitionLabel.alpha = 1
            self.continueButton.alpha = 1
        }
    }
    
    @objc private func handleContinue() {
        // Hide transition UI
        UIView.animate(withDuration: 0.3, animations: {
            self.transitionLabel.alpha = 0
            self.continueButton.alpha = 0
        }) { _ in
            self.transitionLabel.isHidden = true
            self.continueButton.isHidden = true
            
            // Reset for next iteration
            self.currentPhraseIndex = 0
            self.currentIteration += 1 
            
            // Check if we're done with all iterations
            if self.currentIteration > self.totalIterations {
                self.toggleLearnMode()
            } else {
                // Show keyboard interaction view and target letter
                self.learnModeView?.isHidden = false
                self.targetLetterLabel.isHidden = false
                self.updateTargetLetter()
                self.isTransitioning = false
            }
        }
    }
    
    
    private func generateKeyboardLayout() {
        var positionsDict: [String: [String: Any]] = [:]
        
        for (letter, records) in tapRecords {
            // Calculate means
            let count = CGFloat(records.count)
            let meanX = records.reduce(0) { $0 + $1.position.x } / count
            let meanY = records.reduce(0) { $0 + $1.position.y } / count
            
            // Calculate variances
            let varianceX = records.reduce(0) { $0 + pow($1.position.x - meanX, 2) } / count
            let varianceY = records.reduce(0) { $0 + pow($1.position.y - meanY, 2) } / count
            
            // Calculate standard deviations
            let stdDevX = sqrt(varianceX)
            let stdDevY = sqrt(varianceY)
            
            // Calculate extreme points
            let minX = records.map { $0.position.x }.min() ?? 0
            let maxX = records.map { $0.position.x }.max() ?? 0
            let minY = records.map { $0.position.y }.min() ?? 0
            let maxY = records.map { $0.position.y }.max() ?? 0
            
            // Calculate spread (range)
            let spreadX = maxX - minX
            let spreadY = maxY - minY
            
            // Calculate median positions
            let sortedX = records.map { $0.position.x }.sorted()
            let sortedY = records.map { $0.position.y }.sorted()
            
            let medianX = count.truncatingRemainder(dividingBy: 2) == 0
                ? (sortedX[Int(count/2) - 1] + sortedX[Int(count/2)]) / 2
                : sortedX[Int(count/2)]
            let medianY = count.truncatingRemainder(dividingBy: 2) == 0
                ? (sortedY[Int(count/2) - 1] + sortedY[Int(count/2)]) / 2
                : sortedY[Int(count/2)]

                
            // Calculate inter-quartile range (IQR)
            let q1X = sortedX[Int(count * 0.25)]
            let q3X = sortedX[Int(count * 0.75)]
            let q1Y = sortedY[Int(count * 0.25)]
            let q3Y = sortedY[Int(count * 0.75)]
            let iqrX = q3X - q1X
            let iqrY = q3Y - q1Y
            
            // Calculate confidence bounds (using 2 standard deviations = ~95% confidence)
            let confidenceBoundX = stdDevX * 2
            let confidenceBoundY = stdDevY * 2
            
            // Suggested key dimensions based on statistical measures
            let suggestedWidth = max(MIN_WIDTH, confidenceBoundX * 2)  // 2x to cover both sides
            let suggestedHeight = max(MIN_WIDTH, confidenceBoundY * 2)
            
            // Calculate hit accuracy (percentage of taps within 1 std dev of mean)
            let tapsWithinStdDev = records.filter { tap in
                let distanceX = abs(tap.position.x - meanX)
                let distanceY = abs(tap.position.y - meanY)
                return distanceX <= stdDevX && distanceY <= stdDevY
            }.count
            let accuracy = Double(tapsWithinStdDev) / Double(count) * 100
            
            positionsDict[String(letter)] = [
                // Position statistics
                "mean": ["x": meanX, "y": meanY],
                "median": ["x": medianX, "y": medianY],
                "variance": ["x": varianceX, "y": varianceY],
                "stdDev": ["x": stdDevX, "y": stdDevY],
                
                // Range statistics
                "min": ["x": minX, "y": minY],
                "max": ["x": maxX, "y": maxY],
                "spread": ["x": spreadX, "y": spreadY],
                "iqr": ["x": iqrX, "y": iqrY],
                
                // Key size suggestions
                "suggestedSize": [
                    "width": suggestedWidth,
                    "height": suggestedHeight
                ],
                
                // Additional metrics
                "sampleCount": count,
                "accuracy": accuracy,
                "confidenceBounds": [
                    "x": confidenceBoundX,
                    "y": confidenceBoundY
                ]
            ]
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: positionsDict, options: [.prettyPrinted])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("KEYBOARD_LAYOUT:", jsonString)
                
                if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let filePath = documentsPath.appendingPathComponent("keyboard_layout.json")
                    try jsonString.write(to: filePath, atomically: true, encoding: .utf8)
                    print("Saved to:", filePath.path)
                }
            }
        } catch {
            print("Error generating JSON:", error)
        }
    }
    
    private let PIXEL_BOUNDARY: CGFloat = 8.0
    private let MIN_WIDTH: CGFloat = 20.0
    
    @objc private func keyTapped(_ sender: UIButton, event: UIEvent) {
        if let touch = event.allTouches?.first {
            let tapLocation = touch.location(in: keyboard)
            
            switch state {
            case .learn:
                // In learn mode, we don't care about which button was tapped
                recordTapAndAdvance(at: tapLocation)
                
            case .morph:
                // For morph mode, we need the button title
                guard let keyTitle = sender.title(for: .normal) else { return }
                
                let tapLocationInButton = touch.location(in: sender)
                let buttonCenter = sender.bounds.midX
                
                let distanceFromCenter = tapLocationInButton.x - buttonCenter
                
                let rowStackView = keyboard.arrangedSubviews.first { row in
                    guard let rowStackView = row as? UIStackView else { return false }
                    return rowStackView.arrangedSubviews.contains { key in
                        guard let button = key as? UIButton else { return false }
                        return button.currentTitle == sender.currentTitle
                    }
                }
                
                if let stackView = rowStackView as? UIStackView, let index = stackView.arrangedSubviews.firstIndex(of: sender) {
                    if abs(distanceFromCenter) > (sender.bounds.width/2 - PIXEL_BOUNDARY) {
                        let direction: CGFloat = distanceFromCenter > 0 ? 1 : -1
                        let changeAmount: CGFloat = PIXEL_BOUNDARY * direction
                        
                        var morphedNeighbor = false
                        
                        if direction > 0, index + 1 < stackView.arrangedSubviews.count {
                            let nextButton = stackView.arrangedSubviews[index + 1]
                            let newWidth = nextButton.frame.width - abs(changeAmount)
                            
                            if newWidth >= MIN_WIDTH {
                                if let nextWidthConstraint = nextButton.constraints.first(where: { $0.firstAttribute == .width }) {
                                    nextButton.removeConstraint(nextWidthConstraint)
                                }
                                nextButton.widthAnchor.constraint(equalToConstant: newWidth).isActive = true
                                morphedNeighbor = true
                            }
                            
                        } else if direction < 0, index - 1 >= 0 {
                            let previousButton = stackView.arrangedSubviews[index - 1]
                            let newWidth = previousButton.frame.width - abs(changeAmount)
                            
                            if newWidth >= MIN_WIDTH {
                                if let prevWidthConstraint = previousButton.constraints.first(where: { $0.firstAttribute == .width }) {
                                    previousButton.removeConstraint(prevWidthConstraint)
                                }
                                previousButton.widthAnchor.constraint(equalToConstant: newWidth).isActive = true
                                morphedNeighbor = true
                            }
                        }
                        
                        if morphedNeighbor {
                            if let widthConstraint = sender.constraints.first(where: { $0.firstAttribute == .width }) {
                                sender.removeConstraint(widthConstraint)
                            }
                            
                            sender.widthAnchor.constraint(equalToConstant: sender.frame.width + abs(changeAmount)).isActive = true
                        }
                        
                        UIView.animate(withDuration: 0.1) {
                            self.view.layoutIfNeeded()
                        }
                    }
                }
                
            case .default:
                // For default mode, we need the button title
                guard let keyTitle = sender.title(for: .normal) else { return }
                textDocumentProxy.insertText(keyTitle)
            }
        }
    }
    
    deinit {
        cleanupLearnMode()
    }
    
}
