//
//  BreadcrumbRenderer.swift
//  Markup-Maps
//
//  Created by Alan Chu on 2/16/19.
//  Copyright © 2019 Aeta. All rights reserved.
//

import MapKit

public class BreadcrumbRenderer: MKOverlayRenderer {
    override public func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let crumbs = self.overlay as? Breadcrumb else {
            precondition(false, "Expected overlay type to be Breadcrumb.")
        }
        
        let lineWidth = MKRoadWidthAtZoomScale(zoomScale)
        let lineWidthAsDouble = Double(lineWidth)
        
        let clipRect = mapRect.insetBy(dx: -lineWidthAsDouble, dy: -lineWidthAsDouble)
        let path = self.newPath(for: crumbs.points, clipRect: clipRect, zoomScale: zoomScale)
        
        context.addPath(path)
        context.setStrokeColor(red: 0, green: 0, blue: 1.0, alpha: 0.5)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        context.setLineWidth(lineWidth)
        context.strokePath()
    }
    
    fileprivate func newPath(for points: [MKMapPoint],
                 clipRect mapRect: MKMapRect,
                 zoomScale: MKZoomScale) -> CGPath {
        let path = CGMutablePath()
        guard points.count > 1, let firstPoint = points.first else { return path }
        
        var needsMove = true
        
        let MIN_POINT_DELTA: Double = 5
        let minPointDelta = MIN_POINT_DELTA / Double(zoomScale)
        let c2 = squared(minPointDelta)
        
        var lastPoint = firstPoint
        for index in points.indices {
            guard index != 0 else { continue }  // skip first point because it's the first lastPoint value.
            let point = points[index]
            
            let a2b2 = squared(point.x - lastPoint.x) + squared(point.y - lastPoint.y)
            guard a2b2 >= c2 else { continue }
            
            if LineBetweenPointsIntersectsPoints(pointA: point, pointB: lastPoint, rect: mapRect) {
                if needsMove {
                    let lastCGPoint = self.point(for: lastPoint)
                    path.move(to: lastCGPoint)
                }
                
                let cgPoint = self.point(for: point)
                path.addLine(to: cgPoint)
                needsMove = false
            } else {
                needsMove = true
            }
            
            lastPoint = point
        }
        
        let point = points.last!
        if LineBetweenPointsIntersectsPoints(pointA: point, pointB: lastPoint, rect: mapRect) {
            if needsMove {
                let lastCGPoint = self.point(for: lastPoint)
                path.move(to: lastCGPoint)
            }
            
            let cgPoint = self.point(for: point)
            path.addLine(to: cgPoint)
        }
        
        return path
    }
    
    fileprivate func LineBetweenPointsIntersectsPoints(pointA: MKMapPoint, pointB: MKMapPoint, rect: MKMapRect) -> Bool {
        let minX = min(pointA.x, pointB.x)
        let minY = min(pointA.y, pointB.y)
        let maxX = max(pointA.x, pointB.x)
        let maxY = max(pointA.y, pointB.y)
        
        let rectToTest = MKMapRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        return rect.intersects(rectToTest)
    }
    
    fileprivate func squared(_ x: Double) -> Double {
        return x * x
    }
}
