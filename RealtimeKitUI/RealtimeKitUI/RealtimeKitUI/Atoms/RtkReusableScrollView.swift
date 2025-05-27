//
//  RtkReusableScrollView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 06/01/23.
//

import UIKit

protocol PagingScrollViewDataSource: AnyObject {
    func numberOfPages(scrollView: PagingScrollView) -> UInt
    func viewFor(scrollView: PagingScrollView, index: Int) -> Item
}

class Item {
    var view: GridView<RtkParticipantTileView>
    var index: Int
    init(view: GridView<RtkParticipantTileView>, index: Int) {
        self.view = view
        self.index = index
    }
}


class PagingScrollView: UIScrollView {
    
    private var dict = [Int: Item]()
    weak var pagingDatasource: PagingScrollViewDataSource?
    private var totalNumberOfPages: UInt = 0
    private let isDebugModeOn = RealtimeKitUI.isDebugModeOn

    init() {
        super.init(frame: .zero)
        self.isPagingEnabled  = true
        self.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadData() {
        if isDebugModeOn {
            print("Debug RtkUIKit | reloadData of Paging Scroll view")
        }
        resetScrollView()
        if let dataSource = self.pagingDatasource {
            setContentSize(dataSource: dataSource)
            loadInitialPages(numberOfPages: totalNumberOfPages)
        }
    }
    
    func visiblePage() -> [Item]? {
        var result: [Item]?
        if self.bounds.width != 0 {
            let currentPage = Int((self.contentOffset.x / self.bounds.width))
            if currentPage >= 0 && currentPage < totalNumberOfPages {
                result = [Item]()
                if let page = dict[currentPage] {
                    result?.append(page)
                }
                if let page = dict[currentPage+1] {
                    result?.append(page)
                }
                if let page = dict[currentPage-1] {
                    result?.append(page)
                }
                return result
            }
        }
        return nil
    }
    
    private func setContentSize(dataSource: PagingScrollViewDataSource) {
        totalNumberOfPages = dataSource.numberOfPages(scrollView: self)
        self.layoutIfNeeded()
        self.contentSize = CGSize(width: self.bounds.width * CGFloat(totalNumberOfPages), height: self.bounds.height)
    }
    
    private func loadInitialPages(numberOfPages: UInt) {
        let total = min(numberOfPages, 2)
        for i in 0..<Int(total) {
            loadPage(index: i)
        }
    }
}

extension PagingScrollView : UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let currentPage = Int((scrollView.contentOffset.x / scrollView.bounds.width))
        if isDebugModeOn { print("CurrentPage \(currentPage)") }
        if currentPage >= 0 && currentPage < totalNumberOfPages && pagingDatasource != nil {
            var newPageLoaded = false
            if loadPage(index: currentPage) {
                newPageLoaded = true
            }
            if (currentPage+1 < totalNumberOfPages) && loadPage(index: currentPage + 1) {
                newPageLoaded = true
            }
            if (currentPage-1 >= 0) && loadPage(index: currentPage - 1) {
                newPageLoaded = true
            }
            if newPageLoaded {
                removeUnusedPages(currentPageIndex: currentPage)
            }
        }
    }
}

extension PagingScrollView {
    private func resetScrollView() {
        for i in 0..<Int(totalNumberOfPages) {
            if let item = dict.removeValue(forKey: i) {
                item.view.removeFromSuperview()
                if isDebugModeOn { print("Pages removed index \(i)>") }
            }
        }
        dict.removeAll()
    }
    
    @discardableResult  private func loadPage(index:Int) -> Bool {
        
        if isDebugModeOn { print("Pages Trying to load at index \(index)>") }
        
        if dict[index] != nil {
            // Page is already loaded and inside the memory. No need to load again
            
            if isDebugModeOn { print("Pages Already Loaded No need to load index \(index)>") }
            
            return false;
        }
        let scrollWidth = self.bounds.width
        let scrollHeight = self.bounds.height
        if isDebugModeOn {
            print("Debug RtkUIKit | Scroll Widht \(scrollWidth) height \(scrollHeight)")
        }
        
        if index >= 0 && index < totalNumberOfPages && pagingDatasource != nil {
            let item =  self.pagingDatasource!.viewFor(scrollView: self, index: index)
            self.addSubview(item.view)
            item.view.frame = CGRectMake(CGFloat(index)*scrollWidth, 0, scrollWidth, scrollHeight)
            // Insert entry in cache
            dict[index] = item
            if isDebugModeOn { print("Pages New loaded index \(index)>") }
            //Remove unsed pages Only keep +1 and -1 index
            return true
        }
        
        if isDebugModeOn { print("Pages notable to load index \(index)>") }
        
        return false
    }
    
    private func removeUnusedPages(currentPageIndex: Int) {
        //Remove all exceptIndex+1 and index-1 , index
        for i in 0..<Int(totalNumberOfPages) {
            if i != currentPageIndex && i != currentPageIndex+1 && i != currentPageIndex-1 {
                if let item = dict.removeValue(forKey: i) {
                    item.view.removeFromSuperview()
                    if isDebugModeOn { print("Pages removed index \(i)>") }
                }
            }
        }
    }
}
