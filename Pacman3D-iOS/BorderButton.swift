//
//  BorderButton.swift
//  CookNow
//
//  Created by Tobias on 21.06.17.
//  Copyright © 2017 Tobias. All rights reserved.
//

import UIKit

class BorderButton: UIButton {
    
    @IBInspectable var borderColor: UIColor?
    @IBInspectable var borderWidth: CGFloat = 0
    @IBInspectable var cornerRadius: CGFloat = 0

    @IBInspectable var dashed: Bool = false
    
    override func awakeFromNib() {
        self.layer.backgroundColor = self.backgroundColor?.cgColor
        self.layer.borderColor = borderColor?.cgColor
        
        if !dashed {
            self.layer.borderWidth = borderWidth
            self.layer.cornerRadius = cornerRadius
        } else {
            let dashedBorder = CAShapeLayer()
            dashedBorder.fillColor = self.backgroundColor?.cgColor
            dashedBorder.strokeColor = borderColor?.cgColor
            dashedBorder.lineDashPattern = [2, 2]
            dashedBorder.frame = self.bounds
            dashedBorder.path = UIBezierPath(rect: self.bounds).cgPath
            self.layer.addSublayer(dashedBorder)
        }
    }
}
