//
//  LocationViewController.swift
//  NaverMapSample
//
//  Created by jylee-mac on 2021/06/02.
//

import UIKit
import NMapsMap
import AppTrackingTransparency

class LocationViewController: UIViewController {

    //기본 Const
    //초기 GPS값을 가져올 수 없다면 초기 위치를 회사위치로 고정
    let defaultLatitude : CLLocationDegrees = 37.48077827123715
    let defaultLongitude : CLLocationDegrees = 127.12356152608687
    
    //네이버 맵 화면 View
    @IBOutlet weak var naverMapView: NMFNaverMapView!
    
    //위치 좌표 관리 객체
    let locationManager : CLLocationManager = CLLocationManager()
    
//    var stationList : [StationList]?
    let stationList =
        [
            StationList(id: 0, lat: 37.485090572188 , lon: 127.13357657064148),
            StationList(id: 1, lat: 37.485090572188 , lon: 127.13357657064148),
            StationList(id: 2, lat: 37.48098697310194, lon: 127.12900608645484),
            StationList(id: 3, lat: 37.47860303614454, lon: 127.12630241977278),
            StationList(id: 4, lat: 37.47798149723, lon: 127.12024062738548),
            StationList(id: 5, lat: 37.479045773036255, lon: 127.11841672523065)
        ]

    //마커 터치시 발
   

    override func viewDidLoad() {
        super.viewDidLoad()

        initMapView()
        initLocation()
    }

    
    //초기 mapView에 대한 설정값 세팅
    private func initMapView(){
        /* naver map ui 관련*/
        naverMapView.showZoomControls = false //Zoom 컨트롤러 안보이게 [+ / -] 버튼
        naverMapView.showLocationButton = false //Location type 선택 버튼 안보이게
        naverMapView.showCompass = false //나침판 활성화
        naverMapView.showScaleBar = false //스케일바 활성화
        naverMapView.showIndoorLevelPicker = false //실내층

        naverMapView.mapView.logoAlign = .rightTop //네이버 로고 위치
        naverMapView.mapView.logoInteractionEnabled = false //로고 이벤트 (네이버 라이센스 정보) 사용여부
//        naverMapView.mapView.positionMode = .direction //추적 모드 설정
    }

    //초기 Location에 대한 설정값 세팅
    private func initLocation(){
        /* For GPS */
        locationManager.delegate = self //locationManager Delegate 적용
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //배터리에 맞게 권장되는 최적의 정확도
    }

    
    //현재 위치 새로 고침
    @IBAction func onLocationUpdateAction(_ sender: Any) {
        requestCurrentPosition()
    }
  
    func showStationInfo(_ index : Int) {
       //터치 이벤트
        print("정보 : \(stationList[index])")
    }
}

/*
    지도 관련 처리
 */
extension LocationViewController {
    
    //카메라 업데이트 함수
    private func updateCamera(lat : CLLocationDegrees, long : CLLocationDegrees) {
        let camPosition =  NMGLatLng(lat: lat, lng: long)
        let position = NMFCameraPosition(camPosition, zoom: 14, tilt: 0, heading: 0)
        naverMapView.mapView.moveCamera(NMFCameraUpdate(position: position))
    }

    //마커 업데이트 함수
    private func updateMaker(_ stationList : [StationList]) {

        //마커 터치 이벤트
        let markerHandler = { [weak self] (overlay: NMFOverlay) -> Bool in
            print("마커 \(overlay.userInfo["tag"] ?? "tag") 터치됨")
            let lat = overlay.userInfo["lat"] as! Double
            let long = overlay.userInfo["long"] as! Double

            self?.updateCamera(lat: lat, long: long)
            let index = overlay.userInfo["tag"] as? Int

            self?.showStationInfo(index ?? 0)
            return true
        }
        
        for item in stationList {
            let marker = NMFMarker()
            marker.position = NMGLatLng(lat: item.lat, lng: item.lon)
//            marker.iconImage = NMF_MARKER_IMAGE_BLACK
//            marker.iconTintColor = UIColor.red
//            marker.width = 45
//            marker.height = 42
            marker.mapView = self.naverMapView.mapView
            marker.iconImage = NMFOverlayImage(name: "sample-icon")
            marker.userInfo = ["tag" : item.id, "lat" : Double(item.lat), "long" : Double(item.lon)]
            marker.touchHandler = markerHandler
            
            // 정보창 생성
            let infoWindow = NMFInfoWindow()
            infoWindow.open(with: marker)
        }
    }
}

/*
 Location 관련 처리
 */
extension LocationViewController : CLLocationManagerDelegate {

    //권한에 따른 업데이트 처리
    func processLocation(_ status : CLAuthorizationStatus) {
        switch status {
            case .restricted:
                //restrict : 기기 설정에서 유저가 모든 앱이 위치 설정을 사용할 수 없게 꺼 버림
                print("GPS: 기기 설정에서 유저가 모든 앱이 위치 설정을 사용할 수 없게 꺼 버림")
                requestLocationPermission()
            case .denied:
                //denied : 유저가 위치 정보를 이 앱이 접근하는 것을 거부함
                print("GPS: 유저가 위치 정보를 이 앱이 접근하는 것을 거부함")
                //권한 없을 시 유저에게 권한 획득을 위한 요청 처리 추가 필요
                requestLocationPermission()
            case .notDetermined :
                //notDetermined : 위치 권한을 요청받지 않음
                print("GPS: 위치 권한을 요청받지 않음")//권한 없을 시 유저에게 권한 획득을 위한 요청 처리 추가 필요
                locationManager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse : //GPS: 권한 있음
                print("GPS: 권한 있음")
                //authorizedAlways : 유저가 이 앱이 백그라운드에서도 위치 정보에 접근할 수 있도록 허용함
                //authorizedWhenInUse : 유저가 이 앱이 포그라운드에서 위치 정보에 접근할 수 있도록 허용함
                guard let lat = locationManager.location?.coordinate.latitude, let long = locationManager.location?.coordinate.longitude else {
                    return
                }
                updateCamera(lat: lat, long: long)
//                guard let stations = self.stationList else {
//                    return
//                }
                naverMapView.mapView.positionMode = .direction
                updateMaker(stationList)
            default:
                print("GPS: 처리없음")
        }
    }
    
    //현재 위치 화면 이동 요청함수
    func requestCurrentPosition() {
        if CLLocationManager.locationServicesEnabled() {
            //OS 전체 위치 서비스 활성화 여부
            var status : CLAuthorizationStatus
            if #available(iOS 14.0, *) {
                status = locationManager.authorizationStatus
            } else {
                status = CLLocationManager.authorizationStatus()
            }
            processLocation(status)
        }else{
            //OS 전체 위치 서비스 활성화가 안되어 있는 경우 사용자에게 요청
            print("권한요청 3")
            requestLocationPermission()
        }
    }
    
   
    //사용자 권한 허용후 처리
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //사용자 권한 처리 후 처리하는 로직
        print("didChangeAuthorization")
        processLocation(status)
    }
    
    //권한이 없을시 Setting화면으로 유도하는 Alert
    func requestLocationPermission() {
        let alertController = UIAlertController(title: "Location Permission Required", message: "Please enable location permissions in settings.", preferredStyle: .alert)
           
           let okAction = UIAlertAction(title: "Settings", style: .default, handler: {(cAlertAction) in
               //Redirect to Settings app
               UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
           })
           
           let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
           alertController.addAction(cancelAction)
           
           alertController.addAction(okAction)
           
           self.present(alertController, animated: true, completion: nil)
    }
}

