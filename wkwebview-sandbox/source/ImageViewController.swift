//
//  ImageViewController.swift
//  wkwebview-sandbox
//
//  Created by haigo koji on 2019/09/16.
//  Copyright © 2019 haigo koji. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

class ImageViewController: UIViewController {
    
    // MARK: - IBOutlet
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    // MARK: - property
    var currentPage = 0
    private let urls = [
        "https://pics.prcm.jp/d66a3400da63a/81682003/png/81682003_220x220.png",
        "https://d3jks39y9qw246.cloudfront.net/medium/12036/5019cbd57e1d7b01e823a19e8ac39e8bed8a469d.jpg",
        "https://image.news.livedoor.com/newsimage/stf/7/8/78a67_88_ca17d324867c8b09cd3a4f9164ea220a-cm.jpg"
    ]
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageControl()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupscrollView()
        for (page, url) in urls.enumerated() {
            let subScrollView = generateSubScrollView(at: page)
            scrollView.addSubview(subScrollView)
            let imageView = generateImageView(at: page, url: url)
            subScrollView.addSubview(imageView)
        }
        scrollView.setContentOffset(CGPoint(x: calculateX(at: currentPage), y: 0), animated: false)
    }

    // MARK: - function
    private func setupPageControl() {
        pageControl.numberOfPages = urls.count
        pageControl.currentPage = currentPage
        // タップされたときのイベントハンドリングを設定
        pageControl.addTarget(
            self,
            action: #selector(didValueChangePageControl),
            for: .valueChanged
        )
    }

    private func setupscrollView() {
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        // コンテンツ幅 = ページ数 x ページ幅
        scrollView.contentSize = CGSize(
            width: calculateX(at: urls.count),
            height: scrollView.bounds.height
        )
    }

    private func generateSubScrollView(at page: Int) -> UIScrollView {
        let frame = calculateSubScrollViewFrame(at: page)
        let subScrollView = UIScrollView(frame: frame)
        
        subScrollView.delegate = self
        subScrollView.maximumZoomScale = 3.0
        subScrollView.minimumZoomScale = 1.0
        subScrollView.showsHorizontalScrollIndicator = false
        subScrollView.showsVerticalScrollIndicator = false
        
        // ダブルタップされたときのイベントハンドリングを設定
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didDoubleTapSubScrollView(_:)))
        gesture.numberOfTapsRequired = 2
        subScrollView.addGestureRecognizer(gesture)
        
        return subScrollView
    }

    private func generateImageView(at page: Int, url: String) -> UIImageView {
        let imageView = UIImageView(frame: scrollView.bounds)
        let downloader = ImageDownloader()
        let urlRequest = URLRequest(url: URL(string: url)!)
        downloader.download(urlRequest) { response in
            switch response.result {
                case let .success(image):
                    imageView.image = image
                case .failure(_): break
            }
        }
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = image(at: page)
        
        return imageView
    }

    /// ページコントロールを操作された時
    @objc private func didValueChangePageControl() {
        currentPage = pageControl.currentPage
        let x = calculateX(at: currentPage)
        scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
    }

    /// サブスクロールビューがダブルタップされた時
    @objc private func didDoubleTapSubScrollView(_ gesture: UITapGestureRecognizer) {
        guard let subScrollView = gesture.view as? UIScrollView else { return }
        
        if subScrollView.zoomScale < subScrollView.maximumZoomScale {
            // タップされた場所を中心に拡大する
            let location = gesture.location(in: subScrollView)
            let rect = calculateRectForZoom(location: location, scale: subScrollView.maximumZoomScale)
            subScrollView.zoom(to: rect, animated: true)
        } else {
            subScrollView.setZoomScale(subScrollView.minimumZoomScale, animated: true)
        }
    }

    /// ページ幅 x position でX位置を計算
    private func calculateX(at position: Int) -> CGFloat {
        return scrollView.bounds.width * CGFloat(position)
    }

    /// スクロールビューのオフセット位置からページインデックスを計算
    private func calculatePage(of scrollView: UIScrollView) -> Int {
        let width = scrollView.bounds.width
        let offsetX = scrollView.contentOffset.x
        let position = (offsetX - (width / 2)) / width
        return Int(floor(position) + 1)
    }

    /// タップされた位置と拡大率から拡大後のCGRectを計算する
    private func calculateRectForZoom(location: CGPoint, scale: CGFloat) -> CGRect {
        let size = CGSize(
            width: scrollView.bounds.width / scale,
            height: scrollView.bounds.height / scale
        )
        let origin = CGPoint(
            x: location.x - size.width / 2,
            y: location.y - size.height / 2
        )
        return CGRect(origin: origin, size: size)
    }

    /// サブスクロールビューのframeを計算
    private func calculateSubScrollViewFrame(at page: Int) -> CGRect {
        var frame = scrollView.bounds
        frame.origin.x = calculateX(at: page)
        return frame
    }

    private func resetZoomScaleOfSubScrollViews(without exclusionSubScrollView: UIScrollView) {
        for subview in scrollView.subviews {
            guard
                let subScrollView = subview as? UIScrollView,
                subScrollView != exclusionSubScrollView else { continue }
            subScrollView.setZoomScale(subScrollView.minimumZoomScale, animated: false)
        }
    }

    private func image(at page: Int) -> UIImage? {
        return UIImage(named: "\(page)")
    }
}

extension ImageViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView != scrollView { return }
        let page = calculatePage(of: scrollView)
        if page == currentPage { return }
        currentPage = page
        pageControl.currentPage = page
        resetZoomScaleOfSubScrollViews(without: scrollView)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollView.subviews.first as? UIImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard let imageView = scrollView.subviews.first as? UIImageView else { return }
        
        scrollView.contentInset = UIEdgeInsets(
            top: max((scrollView.frame.height - imageView.frame.height) / 2, 0),
            left: max((scrollView.frame.width - imageView.frame.width) / 2, 0),
            bottom: 0,
            right: 0
        )
    }
}
