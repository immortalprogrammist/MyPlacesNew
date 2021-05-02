//
//  RatingControl.swift
//  MyPlaces
//
//  Created by Nikita on 02.05.21.
//

import UIKit

@IBDesignable class RatingControl: UIStackView {
    
    // MARK: Properties
    var rating = 0 {
        didSet {
            updateButtonSelectionState()
        }
    }
    
    private var ratingButtons = [UIButton]()
    
    @IBInspectable var starSize: CGSize = CGSize(width: 44.0, height: 44.0) {
        didSet {
            setupButtons()
        }
    }
    @IBInspectable var starCount: Int = 5 {
        didSet {
            setupButtons()
        }
    }
    
    // MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtons()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }
    
    // MARK: Button Action
    
    // система нажатия кнопок
    @objc func ratingButtonTapped(button: UIButton) {
        
        guard let index = ratingButtons.firstIndex(of: button) else { return } // определяем индекс кнопки, которой касается пользователь
        
        // Подсчитываем рейтинг выделенными кнопками
        let selectedRating = index + 1
        
        if selectedRating == rating {
            rating = 0
        } else {
            rating = selectedRating
        }
    }
    
    // MARK: Private Methods
    
    private func setupButtons() {
        
        // удаляем старые, при создание новых в сториборд
        for button in ratingButtons {
            removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        
        ratingButtons.removeAll()
        
        // Load button image
        let bundle = Bundle(for: type(of: self)) // путь к папке с изображениями
        
        let filledStar = UIImage(named: "filledStar",
                                 in: bundle,
                                 compatibleWith: self.traitCollection)
        
        let emptyStar = UIImage(named: "emptyStar",
                                in: bundle,
                                compatibleWith: self.traitCollection)
        
        let highlightedStar = UIImage(named: "highlightedStar",
                                      in: bundle,
                                      compatibleWith: self.traitCollection)
        
        // создаем кнопки цыклом
        for _ in 0..<starCount {
            
            // create the button
            let button = UIButton()
            
            // устанавливаем изображение кнопки в соответсвие с действиями
            button.setImage(emptyStar, for: .normal) // normal - обычное состояние кнопки.
            button.setImage(filledStar, for: .selected) // selected - выбрана
            button.setImage(highlightedStar, for: .highlighted) // прикосновение к кнопке
            button.setImage(highlightedStar, for: [.highlighted, .selected]) //
            
            // Add constraints
            button.translatesAutoresizingMaskIntoConstraints = false // отключение автоматически сгенерированных констреинтов для кнопки
            button.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true // определили высоту
            button.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true // определили ширину
            
            // Setup the button action
            button.addTarget(self, action: #selector(ratingButtonTapped(button:)), for: .touchUpInside)
            
            // Add the button to the stack
            addArrangedSubview(button)
            
            // Add the new button on the rating button array
            ratingButtons.append(button)
        }
        
        updateButtonSelectionState()
    }
    
    //
    private func updateButtonSelectionState() {
        
        for (index, button) in ratingButtons.enumerated() {
            button.isSelected = index < rating
        }
    }
}
