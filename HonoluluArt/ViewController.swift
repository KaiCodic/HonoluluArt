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
    
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let value: Double
    
    init(name: String, li: Double, lo: Double, v: Double) {
        self.name = name
        self.latitude = li
        self.longitude = lo
        self.value = v
    }
}

class ElementMKCircle: MKCircle {
    
    var elementValue: Double?
    var element: String?
    var selected: Bool = false
    
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let point = MKMapPointForCoordinate(coordinate)
        let mapRect = MKMapRectMake(point.x, point.y, 0, 0)
        return self.intersects(mapRect)
    }
    
}

class ViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var hint: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    let data: [ElementInfo] =
        [ElementInfo(name: "Germany", li: 51.5, lo: 10.5, v: 4000),
         ElementInfo(name: "G1",li: 49.5, lo: 10, v: 200),
         ElementInfo(name: "G2",li: 49.9, lo: 10.2, v: 800),
         ElementInfo(name: "G3",li: 50, lo: 10.2, v: -2000),
         ElementInfo(name: "G4",li: 49.9, lo: 10.2, v: 4000),
         ElementInfo(name: "G5",li: 48.9, lo: 10.5, v: 50),
         ElementInfo(name: "G6",li: 47.9, lo: 10.5, v: 400),
         ElementInfo(name: "G7",li: 47.9, lo: 10.5, v: -50),
         ElementInfo(name: "G8",li: 47.9, lo: 10.5, v: 600),
         ElementInfo(name: "Irland",li: 53, lo: -8, v: 5),
         ElementInfo(name: "South Africa",li: -30, lo: 26, v: 700),
         ElementInfo(name: "Bangkok",li: 13, lo: 100, v: 1700),
         ElementInfo(name: "Luxembourg",li: 49.75, lo: 6.1, v: -5)]
    
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
            return Double.minimum(min, nextValue.latitude)
        }
        
        let minLong = data.reduce(180.0) { (min, nextValue) -> Double in
            return Double.minimum(min, nextValue.longitude)
        }
        
        let maxLat = data.reduce(-90.0) { (min, nextValue) -> Double in
            return Double.maximum(min, nextValue.latitude)
        }
        
        let maxLong = data.reduce(-180.0) { (min, nextValue) -> Double in
            return Double.maximum(min, nextValue.longitude)
        }
        
        /*let maxValue = data.reduce(Double.leastNormalMagnitude) { (max, nextValue) -> Double in
            return Double.maximum(max, nextValue.value)
        }*/
        
        let minValue = data.reduce(Double.greatestFiniteMagnitude) { (min, nextValue) -> Double in
            return Double.minimum(min, nextValue.value)
        }
        
        print("\(minLat),\(minLong),\(maxLat),\(maxLong)")
        centerMapOnLocation(minLat: minLat, minLong: minLong, maxLat: maxLat, maxLong: maxLong)
        

        for info in data{
            let location = CLLocation(latitude: info.latitude, longitude: info.longitude)
            
            //let radius = (info.value > 0 ? (info.value/maxValue * (maxRadius-minRadius) + minRadius) : (abs(info.value)/abs(minValue) * (maxRadius-minRadius) + minRadius))
            
            let radius = (abs(info.value)/abs(minValue) * (maxRadius-minRadius) + minRadius)
    
            let circle = ElementMKCircle(center: location.coordinate, radius: radius)
            circle.elementValue = info.value
            circle.element = info.name
            mapView.add(circle)

        }
    
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if let circleOverlay = overlay as? ElementMKCircle, let value = circleOverlay.elementValue{
            let circleRenderer = MKCircleRenderer(overlay: circleOverlay)
            let color = value > 0.0 ? UIColor.blue : UIColor.red
            circleRenderer.fillColor = color.withAlphaComponent(0.2)
            circleRenderer.strokeColor = color.withAlphaComponent(0.3)
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
                var chosenCircle: ElementMKCircle?
                for circle in self.mapView.overlays as! [ElementMKCircle] {
                    if circle.intersects(mapRect), !circle.selected, (chosenCircle == nil || (chosenCircle?.radius)! > circle.radius ){
                        chosenCircle = circle
                        
                    } else {
                        removeSelectionIfExists(circle: circle)
                    }
                }
                if chosenCircle == nil {
                    hint.isHidden = true
                } else {
                    
                    //self.mapView.remove(circle)
                    //self.mapView.insert(circle, at: 0)
                    if let circle = chosenCircle, let circleRenderer = self.mapView.renderer(for: circle) as? MKCircleRenderer, let name = circle.element, let value = circle.elementValue {
                        let msg =  " " + name + " value: " + String(value) + " "
                        hint.isHidden = false
                        hint.text = msg
                        hint.sizeToFit()
                        let color = value > 0.0 ? UIColor.blue : UIColor.red
                        circleRenderer.strokeColor = color.withAlphaComponent(0.9)
                        self.mapView.renderer(for: circle)
                        circle.selected = true
                    }
                    
                }
            }
        }
        
        super.touchesEnded(touches, with: event)
     
    }
    
    func removeSelectionIfExists(circle: ElementMKCircle){
        if circle.selected {
            if let circleRenderer = self.mapView.renderer(for: circle) as? MKCircleRenderer, let value = circle.elementValue {
                circle.selected = false
                let color = value > 0.0 ? UIColor.blue : UIColor.red
                circleRenderer.strokeColor = color.withAlphaComponent(0.3)
                self.mapView.renderer(for: circle)
            }
        }
    }
    
    func centerMapOnLocation(minLat: Double, minLong: Double, maxLat: Double, maxLong: Double ) {
        
        let start = CLLocationCoordinate2DMake(Double.minimum(maxLat+3, 90),Double.maximum(minLong-6, -180) )
        let end = CLLocationCoordinate2DMake(Double.maximum(minLat-3, -90),Double.minimum(maxLong+6, 180) )
        let origin = MKMapPointForCoordinate(start);
        let endpoint = MKMapPointForCoordinate(end);
        let size = MKMapSize(width: abs(endpoint.x-origin.x), height: abs(endpoint.y-origin.y))
        let coordinateRegion = MKCoordinateRegionForMapRect(MKMapRect(origin: origin, size: size))
        mapView.setRegion(coordinateRegion, animated: true)
    }


}

