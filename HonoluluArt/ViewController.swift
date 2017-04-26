//
//  ViewController.swift
//  HonoluluArt
//
//  Created by Kais Haddadin on 26.04.17.
//  Copyright © 2017 Kais Haddadin. All rights reserved.
//

import UIKit
import MapKit

class ElementInfo {
    
    public let latitude: Double
    public let longitude: Double
    public let value: Double
    
    init(li: Double, lo: Double, v: Double) {
        self.latitude = li
        self.longitude = lo
        self.value = v
    }
}

class ElementMKCircle: MKCircle {
    
    var elementValue: Double?
    var element: String?
    
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let point = MKMapPointForCoordinate(coordinate)
        let mapRect = MKMapRectMake(point.x, point.y, 0, 0)
        return self.intersects(mapRect)
    }
    
}

class ViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var hint: UILabel!

    @IBOutlet weak var mapView: MKMapView!
    // lat, long
    let data: [String: ElementInfo] = ["Germany": ElementInfo(li: 51.5, lo: 10.5, v: 10), "Irland": ElementInfo(li: 53, lo: -8, v: 5), "Luxembourg": ElementInfo(li: 49.75, lo: 6.1, v: -5)]
    let regionRadius: CLLocationDistance = 1000
    let maxRadius: Double = 200000
    let minRadius: Double = 50000
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        mapView.delegate = self
        hint.layer.masksToBounds = true
        hint.layer.cornerRadius = 8.0
        hint.isHidden = true
        self.mapView.addSubview(hint)
        self.mapView.bringSubview(toFront: hint)
        
        let minLat = data.reduce(90.0) { (min, nextValue) -> Double in
            return Double.minimum(min, nextValue.value.latitude)
        }
        
        let minLong = data.reduce(180.0) { (min, nextValue) -> Double in
            return Double.minimum(min, nextValue.value.longitude)
        }
        
        let maxLat = data.reduce(-90.0) { (min, nextValue) -> Double in
            return Double.maximum(min, nextValue.value.latitude)
        }
        
        let maxLong = data.reduce(-180.0) { (min, nextValue) -> Double in
            return Double.maximum(min, nextValue.value.longitude)
        }
        
        let maxValue = data.reduce(Double.leastNormalMagnitude) { (max, nextValue) -> Double in
            return Double.maximum(max, nextValue.value.value)
        }
        
        let minValue = data.reduce(Double.greatestFiniteMagnitude) { (min, nextValue) -> Double in
            return Double.minimum(min, nextValue.value.value)
        }
        
        print("\(minLat),\(minLong),\(maxLat),\(maxLong)")
        centerMapOnLocation(minLat: minLat, minLong: minLong, maxLat: maxLat, maxLong: maxLong)
        

        for (key, info) in data{
            let location = CLLocation(latitude: info.latitude, longitude: info.longitude)
            
            let radius = (info.value > 0 ? (info.value/maxValue * (maxRadius-minRadius) + minRadius) : (abs(info.value)/abs(minValue) * (maxRadius-minRadius) + minRadius))
    
            let circle = ElementMKCircle(center: location.coordinate, radius: radius)
            circle.elementValue = info.value
            circle.element = key
            mapView.add(circle)

        }
    
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if let circleOverlay = overlay as? ElementMKCircle, let value = circleOverlay.elementValue{
            let circleRenderer = MKCircleRenderer(overlay: circleOverlay)
            let color = value > 0.0 ? UIColor.blue : UIColor.red
            circleRenderer.fillColor = color.withAlphaComponent(0.2)
            circleRenderer.strokeColor = color.withAlphaComponent(0.5)
            return circleRenderer
        }
        
        return MKCircleRenderer()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if touch.tapCount == 1 {
                let touchLocation = touch.location(in: self.mapView)
                let locationCoordinate = self.mapView.convert(touchLocation, toCoordinateFrom: self.mapView)
                let point = MKMapPointForCoordinate(locationCoordinate)
                let mapRect = MKMapRectMake(point.x, point.y, 0, 0);
                var circles: [ElementMKCircle] = []
                for circle in self.mapView.overlays as! [ElementMKCircle] {
                    if circle.intersects(mapRect) {
                        if let name = circle.element, let value = circle.elementValue {
                            let msg =  " " + name + " value: " + String(value) + " "
                            if hint.text == msg{
                                hint.isHidden = true
                            }else {
                                hint.isHidden = false
                                hint.text = msg
                                hint.sizeToFit()
                            }
                            
                            circles.append(circle)
                        }
                        
                    }
                }
                if circles.count == 0 {
                    hint.isHidden = true
                }
            }
        }
        
        super.touchesEnded(touches, with: event)
     
    }
    
    func centerMapOnLocation(minLat: Double, minLong: Double, maxLat: Double, maxLong: Double ) {
        
        let start = CLLocationCoordinate2DMake(Double.maximum(minLat-3, -90),Double.maximum(minLong-10, -180) )
        let end = CLLocationCoordinate2DMake(Double.minimum(maxLat+3, 90),Double.minimum(maxLong+10, 180) )
        let origin = MKMapPointForCoordinate(start);
        let endpoint = MKMapPointForCoordinate(end);
        let size = MKMapSize(width: abs(endpoint.x-origin.x), height: abs(endpoint.y-origin.y))
        let coordinateRegion = MKCoordinateRegionForMapRect(MKMapRect(origin: origin, size: size))
        mapView.setRegion(coordinateRegion, animated: true)
    }


}

