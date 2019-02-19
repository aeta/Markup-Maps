//
//  ViewController.swift
//  Markup-Maps
//
//  Created by Alan Chu on 11/19/18.
//  Copyright © 2018 Aeta. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet fileprivate weak var mapView: MKMapView! {
        didSet {
            self.mapView.delegate = self
        }
    }
    
    fileprivate var crumbs: [Breadcrumb] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rect = MKMapRect(origin: MKMapPoint(CLLocationCoordinate2D(latitude: 47.5789, longitude: -122.1401)), size: MKMapSize(width: 5000, height: 5000))
        self.mapView.setVisibleMapRect(rect, animated: false)
        self.mapView.isScrollEnabled = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer { super.touchesBegan(touches, with: event) }
        
        guard let touch = touches.first else { return }
        let point = touch.preciseLocation(in: self.mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: self.mapView)
        
        let newCrumbs = Breadcrumb(withCenterCoordinate: coordinate)
        self.crumbs.append(newCrumbs)
        self.mapView.addOverlay(newCrumbs, level: .aboveRoads)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer { super.touchesMoved(touches, with: event) }
        
        guard let firstTouch = touches.first else { return }
        let point = firstTouch.preciseLocation(in: self.mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: self.mapView)
        
        self.insertIntoMap(coordinate: coordinate)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard let crumbs = self.crumbs.last else { return }
        print("Number of points: \(crumbs.points.count) (allocated cap: \(crumbs.points.capacity))")
    }
    
    func insertIntoMap(coordinate: CLLocationCoordinate2D) {
        guard let crumbs = self.crumbs.last else { return }
        let results = crumbs.add(coordinate: coordinate)
        
        if results.boundingMapRectChanged {
            self.mapView.addOverlay(crumbs, level: .aboveRoads)
            
            let rect = crumbs.boundingMapRect
            let points: [MKMapPoint] = [
                MKMapPoint(x: rect.minX, y: rect.minY),
                MKMapPoint(x: rect.minX, y: rect.maxY),
                MKMapPoint(x: rect.maxX, y: rect.maxY),
                MKMapPoint(x: rect.maxX, y: rect.minY)
            ]
            
            let boundingMapRectOverlay = MKPolygon(points: points, count: points.count)
            self.mapView.addOverlay(boundingMapRectOverlay, level: .aboveRoads)
        } else if !results.result.isNull {
            let currentZoomScale: MKZoomScale = self.mapView.bounds.size.width / CGFloat(self.mapView.visibleMapRect.size.width)
            let lineWidth = Double(MKRoadWidthAtZoomScale(currentZoomScale))
            
            let updateRect = results.result.insetBy(dx: -lineWidth, dy: -lineWidth)
            crumbs.renderer.setNeedsDisplay(updateRect)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let breadcrumb = overlay as? Breadcrumb {
            return breadcrumb.renderer
        } else {
            return MKOverlayRenderer()
        }
    }
}
