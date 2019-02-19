// Refactored into Swift (for use in Playgrounds).
// Original source: "Breadcrumb" by Apple Inc.

//
//  Breadcrumb.swift
//  Markup-Maps
//
//  Created by Alan Chu on 2/16/19.
//  Copyright © 2019 Aeta. All rights reserved.
//

import MapKit
import Foundation

public class Breadcrumb: NSObject, MKOverlay {
    public typealias AddCoordinateCompletion = (result: MKMapRect, boundingMapRectChanged: Bool)
    
    public var minimumDeltaInMeters: CLLocationDistance = 5
    
    public var boundingMapRect: MKMapRect
    public var coordinate: CLLocationCoordinate2D {
        return queue.sync { () -> CLLocationCoordinate2D in
            return points.first!.coordinate
        }
    }
    
    public var points: [MKMapPoint] = []
    public lazy var renderer: BreadcrumbRenderer = BreadcrumbRenderer(overlay: self)
    fileprivate var queue = DispatchQueue(label: "markupmaps.crumbpath.queue")
    
    public init(withCenterCoordinate centerCoordinate: CLLocationCoordinate2D) {
        let origin = MKMapPoint(centerCoordinate)
        self.points.append(origin)
        
        let oneKilometerInMapPoints = 1000 * MKMapPointsPerMeterAtLatitude(centerCoordinate.latitude)
        let oneSquareKilometer = MKMapSize(width: oneKilometerInMapPoints, height: oneKilometerInMapPoints)
        boundingMapRect = MKMapRect(origin: origin, size: oneSquareKilometer)
        boundingMapRect = boundingMapRect.intersection(MKMapRect.world)
    }
    
    func grow(overlayBounds: MKMapRect, toInclude otherRect: MKMapRect) -> MKMapRect {
        var grownBounds = overlayBounds.union(otherRect)
        let oneKilometerInMapPoints = 1000 * MKMapPointsPerMeterAtLatitude(otherRect.origin.coordinate.latitude)
        
        if otherRect.minY < overlayBounds.minY {
            grownBounds.origin.y -= oneKilometerInMapPoints
            grownBounds.size.height += oneKilometerInMapPoints
        }
        
        if otherRect.maxY > overlayBounds.maxY {
            grownBounds.size.height += oneKilometerInMapPoints
        }
        
        if otherRect.minX < overlayBounds.minX {
            grownBounds.origin.x -= oneKilometerInMapPoints
            grownBounds.size.width += oneKilometerInMapPoints
        }
        
        if otherRect.maxX > overlayBounds.maxX {
            grownBounds.size.width += oneKilometerInMapPoints
        }
        
        grownBounds = grownBounds.intersection(MKMapRect.world)
        
        return grownBounds
    }
    
    func mapRectContaining(_ pointA: MKMapPoint, and pointB: MKMapPoint) -> MKMapRect {
        let pointSize = MKMapSize(width: 0, height: 0)
        let newPointRect = MKMapRect(origin: pointA, size: pointSize)
        let previousPointRect = MKMapRect(origin: pointB, size: pointSize)
        
        return newPointRect.union(previousPointRect)
    }
    
    public func add(coordinate newCoordinate: CLLocationCoordinate2D) -> AddCoordinateCompletion {
        return queue.sync { () -> AddCoordinateCompletion in
            var boundingMapRectChanged = false
            var updateRect = MKMapRect.null
            
            let newPoint = MKMapPoint(newCoordinate)
            
            let previousPoint = self.points.last!
            let metersApart = newPoint.distance(to: previousPoint)
            
            if metersApart > self.minimumDeltaInMeters {
                self.points.append(newPoint)
                
                updateRect = self.mapRectContaining(newPoint, and: previousPoint)
                
                let overlayBounds = self.boundingMapRect
                if !overlayBounds.contains(updateRect) {
                    self.boundingMapRect = self.grow(overlayBounds: overlayBounds, toInclude: updateRect)
                    boundingMapRectChanged = true
                }
            }
            
            return (updateRect, boundingMapRectChanged)
        }
    }
}
