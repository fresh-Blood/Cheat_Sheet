//
//  CustomCellTableViewCell.swift
//  Cheat sheet
//
//  Created by Ярослав Куприянов on 01.02.2022.
//

import UIKit

class CustomCell: UITableViewCell {
    
    let languageNameLabel: UILabel = {
       let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.adjustsFontSizeToFitWidth = true
        lbl.font = .systemFont(ofSize: 20, weight: .bold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(languageNameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        languageNameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10).isActive = true
        languageNameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 10).isActive = true
        languageNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 10).isActive = true
        languageNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
    }
    
}
