//
//  CoreTextHeaderFooter.swift
//  SYRefreshExampleforSwift
//
//  Created by shusy on 2017/6/16.
//  Copyright © 2017年 SYRefresh. All rights reserved.
//

import UIKit
import CoreText
import CoreGraphics

class CoreTextHeaderFooter: RefreshView {
    fileprivate var textItem:TextItem //文本视图
    fileprivate lazy var pathLayer:CAShapeLayer = { //创建文字形状
        let path = self.textPath()
        path.move(to: CGPoint.zero)
        let shapplayer = CAShapeLayer()
        shapplayer.bounds = path.cgPath.boundingBoxOfPath
        shapplayer.path = path.cgPath
        shapplayer.isGeometryFlipped = true
        shapplayer.strokeColor = self.textItem.label.textColor.cgColor
        shapplayer.fillColor = nil
        shapplayer.lineWidth = 1
        shapplayer.strokeEnd = 0.0
        return shapplayer
    }()
    fileprivate lazy var gradientLayer:CAGradientLayer = {//创建渐变图层
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.white.withAlphaComponent(0.85).cgColor,UIColor.white.withAlphaComponent(0.25).cgColor,UIColor.white.withAlphaComponent(0.85).cgColor]
        gradientLayer.locations = [0,0.5,0.75]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [0,0,0.25]
        animation.toValue = [0.65,1,1]
        animation.duration = 2
        animation.repeatCount = Float(UInt.max)
        gradientLayer.add(animation, forKey: nil)
        gradientLayer.speed = 0
        self.layer.addSublayer(gradientLayer)
        return gradientLayer
    }()
    
    /// 创建一个富文本刷新控件
    /// - Parameters:
    ///   - data:  gif数据
    ///   - textItem: 提示文本 TextItem对象
    ///   - orientation: 刷新控件的方向
    ///   - height: 刷新控件的高度
    ///   - contentMode: gif图片显示模式
    ///   - completion: 开始刷新之后回调
    init(textItem:TextItem,orientation:RefreshViewOrientation,height:CGFloat,completion:@escaping ()->Void){
        self.textItem = textItem
        super.init(orientaton: orientation, height: height, completion: completion)
        addSubview(textItem.label)
        textItem.label.isHidden = true
        self.layer.addSublayer(pathLayer)
        self.layer.addSublayer(gradientLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateRefreshState(isRefreshing: Bool) {
        textItem.updateRefreshState(isRefreshing: isRefreshing)
        if isRefreshing {
            self.pathLayer.removeFromSuperlayer()
            textItem.label.isHidden = false
            startAnimation()
        }else{
            self.layer.addSublayer(self.pathLayer)
            textItem.label.isHidden = true
            self.gradientLayer.speed = 0

        }
    }
    
    override func updatePullProgress(progress: CGFloat) {
        if ((progress < 1 && progress > 0)){
            self.pathLayer.strokeEnd = (progress - 0.5) * 2;
        }else if(progress >= 1){
            self.pathLayer.strokeEnd = 1;
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.pathLayer.position = CGPoint(x: bounds.width * 0.5 , y: bounds.height * 0.5+8)
        self.textItem.label.center = CGPoint(x: bounds.width * 0.5 , y: bounds.height * 0.5+8)
        self.gradientLayer.frame = self.textItem.label.frame
    }
}

extension CoreTextHeaderFooter {
    /// 返回字符串的字形路径
    /// - Parameter font: 字体
    /// - Returns: 字形路径
    fileprivate func textPath()->UIBezierPath{
        let font:UIFont = self.textItem.label.font
        let ctFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil) //创建一个font的引用
        let attributedStr = NSAttributedString(string: self.textItem.label.text!, attributes: [kCTFontAttributeName as String : ctFont]) //创建富文本
        let letters = CGMutablePath() //创建排版
        let line = CTLineCreateWithAttributedString(attributedStr) //为富文本创建CTLine对象 一个CTLine表示一行
        let runs = CTLineGetGlyphRuns(line) //根据line对象创建字形数组 数组里面每个元素都是CTRun对象 一个CTRun表示一行里连在一起相同属性的文字
        for index in 0..<CFArrayGetCount(runs) {
            let arr = runs
            let run = unsafeBitCast(CFArrayGetValueAtIndex(arr, index), to: CTRun.self)
            let font = unsafeBitCast(CFDictionaryGetValue(CTRunGetAttributes(run), Unmanaged.passUnretained(kCTFontAttributeName).toOpaque()), to: CTFont.self)//获取字体
            for indexR in 0..<CTRunGetGlyphCount(run) { // 遍历CTRun对应的字形
                let glyphRange = CFRangeMake(indexR, 1) //创建字形的区域
                var glyph:CGGlyph = UInt16()
                var position:CGPoint = CGPoint.zero
                CTRunGetGlyphs(run, glyphRange, &glyph)  //获取当前CTRun区域的字形
                CTRunGetPositions(run, glyphRange, &position)//获取当前CTRun区域的位置
                let letter = CTFontCreatePathForGlyph(font, glyph, nil) //为字形创建路径
                let transform  = CGAffineTransform(translationX: position.x, y: position.y)//获取对应位置
                letters.addPath(letter!, transform: transform)//添加路径到排版中
            }
        }
      return UIBezierPath(cgPath: letters)
    }
    
    /// 开始动画
    fileprivate func startAnimation(){
        let pausedTime = self.gradientLayer.timeOffset
        self.gradientLayer.speed = 1.0;
        self.gradientLayer.beginTime = 0.0;
        let timeSincePause = self.gradientLayer.convertTime(CACurrentMediaTime(), from: nil)-pausedTime
        self.gradientLayer.beginTime = timeSincePause;
    }
}