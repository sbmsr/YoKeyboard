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
    
    private var keyboard: UIStackView!
    private var morphButton: UIButton!
    private var learnButton: UIButton!
    private var targetLetterLabel: UILabel!
    
    private var state: State = .default
    private var isMorphModeEnabled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
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
            rowStackView.distribution = .fillProportionally
            rowStackView.spacing = 4
            rowStackView.translatesAutoresizingMaskIntoConstraints = false
            
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
                rowStackView.addArrangedSubview(key)
            }
            keyboard.addArrangedSubview(rowStackView)
        }
        
        // Setup all constraints together
        NSLayoutConstraint.activate([
            // Keyboard constraints
            keyboard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            keyboard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            keyboard.topAnchor.constraint(equalTo: targetLetterLabel.bottomAnchor, constant: 20),  // Position below target letter
            keyboard.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),  // Keep bottom anchored
            
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
        
        @objc private func toggleLearnMode() {
            switch state {
            case .default:
                state = .learn
                isMorphModeEnabled = false
                morphButton.isEnabled = false
                learnButton.setTitle("Stop", for: .normal)  // Shortened toggle text
                targetLetterLabel.isHidden = false
                targetLetterLabel.text = "t"
                
                // Make keys invisible but keep them tappable
                keyboard.arrangedSubviews.forEach { rowView in
                    guard let row = rowView as? UIStackView else { return }
                    row.arrangedSubviews.forEach { button in
                        guard let button = button as? UIButton else { return }
                        button.setTitle("", for: .normal)
                        button.backgroundColor = .clear
                        button.layer.borderColor = UIColor.clear.cgColor
                    }
                }
                
            case .learn:
                state = .default
                morphButton.isEnabled = true
                learnButton.setTitle("Learn", for: .normal)  // Shortened toggle text
                targetLetterLabel.isHidden = true
                
                // Restore key visibility
                for (rowIndex, row) in keys.enumerated() {
                    guard let rowStack = keyboard.arrangedSubviews[rowIndex] as? UIStackView else { continue }
                    for (keyIndex, key) in row.enumerated() {
                        guard let button = rowStack.arrangedSubviews[keyIndex] as? UIButton else { continue }
                        button.setTitle(key, for: .normal)
                        button.backgroundColor = .white
                        button.layer.borderColor = UIColor.white.cgColor
                    }
                }
                
            case .morph:
                return
            }
        }

    
    private let PIXEL_BOUNDARY: CGFloat = 8.0
    private let MIN_WIDTH: CGFloat = 20.0

    @objc private func keyTapped(_ sender: UIButton, event: UIEvent) {
        guard let keyTitle = sender.title(for: .normal) else { return }
        
        if let touch = event.allTouches?.first {
            let tapLocation = touch.location(in: keyboard)
            
            switch state {
            case .learn:
                // Record the tap location for learning
                NSLog("Learn mode tap at: \(tapLocation)")
                // TODO: Record this position for the current target letter
                
            case .morph:
                // Handle morph mode logic
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
                break
            }
        }
        
        // Only insert text in default mode
        if state == .default {
            textDocumentProxy.insertText(keyTitle)
        }
    }
}
