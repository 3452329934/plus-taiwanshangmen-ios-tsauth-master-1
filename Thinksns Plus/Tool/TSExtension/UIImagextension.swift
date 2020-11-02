//
//  UIImagextension.swift
//  ThinkSNSPlus
//
//  Created by IMAC on 2018/7/13.
//  Copyright © 2018年 ZhiYiCX. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    // 修复图片旋转
    func fixOrientation() -> UIImage {
        if self.imageOrientation == .up {
            print("图片为正向")
            return self
        }
        guard let aCgImage = self.cgImage else {
            print("Error: 该image没有CGImage")
            return self
        }
        var transform = CGAffineTransform.identity
        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: .pi)
            break
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
            break
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: self.size.height)
            transform = transform.rotated(by: -.pi / 2)
            break
        default:
            break
        }

        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: self.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break
        default:
            break
        }
        /// 修正bitmapInfo错误导致CGContext生成为空的情况
        let colorSpace = aCgImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: aCgImage.bitmapInfo.rawValue) != nil ? aCgImage.bitmapInfo.rawValue : 1
        if let ctx = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: aCgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo) {
            ctx.concatenate(transform)
            switch self.imageOrientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                ctx.draw(self.cgImage!, in: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(self.size.height), height: CGFloat(self.size.width)))
                break
            default:
                ctx.draw(self.cgImage!, in: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(self.size.width), height: CGFloat(self.size.height)))
                break
            }
            if let cgimg: CGImage = ctx.makeImage() {
                return UIImage(cgImage: cgimg)
            } else {
                print("Error: CGContext 生成图片失败，返回了原图")
                return self
            }
        } else {
            print("Error: CGContext 生成失败，返回了原图")
            return self
        }
    }
    // MARK: - 获取灰度图片
    func grayscaled() -> UIImage? {
        guard let cgImage = self.cgImage else {
            return nil
        }
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let (width, height) = (Int(size.width), Int(size.height))
        // 构建上下文：每个像素一个字节，无alpha
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
                return nil
        }
        // 绘制上下文
        let destination = CGRect(origin: .zero, size: size)
        context.draw(cgImage, in: destination)
        // 返回灰度图片
        guard let imageRef = context.makeImage() else {
                return nil
        }
        return UIImage(cgImage: imageRef)
    }

    /// 修复方向并调整最小边至目标尺寸
    func fixOrientationScaleMinSide(tPixs: CGFloat) -> UIImage {
        if self.imageOrientation == .up && (self.size.width <= tPixs || self.size.height <= tPixs) {
            print("图片为正向且最小边小于等于设置tPixs参数")
            return self
        }
        guard let aCgImage = self.cgImage else {
            print("Error: 该image没有CGImage")
            return self
        }
        guard tPixs > 0 else {
            print("Error: 最小边长tPixs错误")
            return self
        }
        var transform = CGAffineTransform.identity
        switch self.imageOrientation {
            case .down, .downMirrored:
                transform = transform.translatedBy(x: self.size.width, y: self.size.height)
                transform = transform.rotated(by: .pi)
                break
            case .left, .leftMirrored:
                transform = transform.translatedBy(x: self.size.width, y: 0)
                transform = transform.rotated(by: .pi / 2)
                break
            case .right, .rightMirrored:
                transform = transform.translatedBy(x: 0, y: self.size.height)
                transform = transform.rotated(by: -.pi / 2)
                break
            default:
                break
        }

        switch self.imageOrientation {
            case .upMirrored, .downMirrored:
                transform = transform.translatedBy(x: self.size.width, y: 0)
                transform = transform.scaledBy(x: -1, y: 1)
                break
            case .leftMirrored, .rightMirrored:
                transform = transform.translatedBy(x: self.size.height, y: 0)
                transform = transform.scaledBy(x: -1, y: 1)
                break
            default:
                break
        }
        /// 计算缩放比例
        var sacleSize: CGFloat = 0
        var tWidth: CGFloat = 0
        var tHeight: CGFloat = 0
        if self.size.height >= self.size.width {
            sacleSize = tPixs / self.size.width
            tWidth = tPixs
            tHeight = self.size.height * sacleSize
        } else {
            sacleSize = tPixs / self.size.height
            tWidth = self.size.width * sacleSize
            tHeight = tPixs
        }
        /// 修正bitmapInfo错误导致CGContext生成为空的情况
        let colorSpace = aCgImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: aCgImage.bitmapInfo.rawValue) != nil ? aCgImage.bitmapInfo.rawValue : 1
        if let ctx = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: aCgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo) {
            ctx.concatenate(transform)
            switch self.imageOrientation {
                case .left, .leftMirrored, .right, .rightMirrored:
                    ctx.draw(self.cgImage!, in: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(self.size.height), height: CGFloat(self.size.width)))
                    break
                default:
                    ctx.draw(self.cgImage!, in: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(self.size.width), height: CGFloat(self.size.height)))
                    break
            }
            if let cgimg: CGImage = ctx.makeImage() {
                /// 重绘图片大小大小
                UIGraphicsBeginImageContext(CGSize(width: tWidth, height: tHeight))
                var getImage = UIImage(cgImage: cgimg, scale: 1, orientation: UIImage.Orientation.up)
                getImage.draw(in: CGRect(x: 0, y: 0, width: tWidth, height: tHeight))
                getImage = UIGraphicsGetImageFromCurrentImageContext()!
                return getImage
            } else {
                print("CGContext 生成图片失败，返回了原图")
                return self
            }
        } else {
            print("CGContext 生成失败，返回了原图")
            return self
        }
    }
}
