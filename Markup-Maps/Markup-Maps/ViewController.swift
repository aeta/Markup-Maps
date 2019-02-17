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
    
    fileprivate var crumbs: CrumbPath?
    fileprivate var crumbRenderer: CrumbPathRenderer?
    
    fileprivate var tempTouchesStorage = [CLLocationCoordinate2D]() {
        didSet {
            print(tempTouchesStorage.count)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rect = MKMapRect(origin: MKMapPoint(CLLocationCoordinate2D(latitude: 47.5789, longitude: -122.1401)), size: MKMapSize(width: 5000, height: 5000))
        self.mapView.setVisibleMapRect(rect, animated: false)
        self.mapView.isScrollEnabled = false
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let firstTouch = touches.first else { return }
        let point = firstTouch.preciseLocation(in: self.mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: self.mapView)
        
        self.insertIntoMap(coordinate: coordinate)
        
//        super.touchesMoved(touches, with: event)
    }
    
    func insertIntoMap(coordinate: CLLocationCoordinate2D) {
        if let crumbs = self.crumbs {
            let results = crumbs.add(coordinate: coordinate)
            
            if results.boundingMapRectChanged {
                self.mapView.removeOverlays(self.mapView.overlays)
                self.crumbRenderer = nil
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
                self.crumbRenderer!.setNeedsDisplay(updateRect)
            }
        } else {
            self.crumbs = CrumbPath(withCenterCoordinate: coordinate)
            self.mapView.addOverlay(self.crumbs!, level: .aboveRoads)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is CrumbPath {
            if self.crumbRenderer == nil {
                self.crumbRenderer = CrumbPathRenderer(overlay: overlay)
            }
            
            return self.crumbRenderer!
        } else {
            return MKOverlayRenderer()
        }
    }
}
