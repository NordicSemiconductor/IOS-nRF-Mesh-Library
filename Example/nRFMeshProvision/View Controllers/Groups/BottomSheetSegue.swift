//
//  BottomSheetSegue.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 29/08/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class BottomSheetSegue: UIStoryboardSegue {

    private var selfRetained: BottomSheetSegue? = nil
    
    override func perform() {
        selfRetained = self
        destination.transitioningDelegate = self
        destination.modalPresentationStyle = .overCurrentContext
        // To display the BottomSheet above the TabBar, present
        // the sheet from the TabBarController itself.
        let tabBarController = source.navigationController?.parent
        tabBarController?.present(destination, animated: true)
    }
}

extension BottomSheetSegue: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return Presenter()
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        selfRetained = nil
        return Dismisser()
    }
    
}

extension BottomSheetSegue {
    
    private class Presenter: NSObject, UIViewControllerAnimatedTransitioning {
        
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return 0.5
        }
        
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            let container = transitionContext.containerView
            let toView = transitionContext.view(forKey: .to)!
            let toViewController = transitionContext.viewController(forKey: .to)!
            let fromViewController = transitionContext.viewController(forKey: .from)!
            
            // Configure the layout.
            do {
                toView.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(toView)
                
                if #available(iOS 11.0, *) {
                    container.safeAreaLayoutGuide.centerYAnchor.constraint(equalTo: toView.centerYAnchor, constant: 0).isActive = true
                    container.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: toView.leadingAnchor, constant: -20).isActive = true
                    container.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: toView.trailingAnchor, constant: 20).isActive = true
                } else {
                    container.centerYAnchor.constraint(equalTo: toView.centerYAnchor, constant: 0).isActive = true
                    container.leadingAnchor.constraint(equalTo: toView.leadingAnchor, constant: -20).isActive = true
                    container.trailingAnchor.constraint(equalTo: toView.trailingAnchor, constant: 20).isActive = true
                }
                
                if let navigationController = toViewController as? UINavigationController,
                    let bottomSheet = navigationController.topViewController as? BottomSheetViewController {
                    let navBarHeight = navigationController.navigationBar.frame.height
                    let subtitleCellHeight = 56
                    let itemsCount = min(5, bottomSheet.models.count)
                    let height = navBarHeight + CGFloat(itemsCount * subtitleCellHeight)
                    toView.heightAnchor.constraint(equalToConstant: height).isActive = true
                } else {
                    // Respect `toViewController.preferredContentSize.height` if non-zero.
                    if toViewController.preferredContentSize.height > 0 {
                        toView.heightAnchor.constraint(equalToConstant: toViewController.preferredContentSize.height).isActive = true
                    }
                }
            }
            
            // Apply some styling.
            do {
                toView.layer.masksToBounds = true
                toView.layer.cornerRadius = 20
            }
            
            // Perform the animation.
            do {
                container.layoutIfNeeded()
                toView.transform = CGAffineTransform(scaleX: 0, y: 0)
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8,
                               initialSpringVelocity: 0, options: [], animations: {
                    toView.transform = CGAffineTransform.identity
                    fromViewController.view.alpha = 0.5
                }) { completed in
                    transitionContext.completeTransition(completed)
                }
            }
        }
    }

    private class Dismisser: NSObject, UIViewControllerAnimatedTransitioning {
        
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return 0.2
        }
        
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            let fromView = transitionContext.view(forKey: .from)!
            let toViewController = transitionContext.viewController(forKey: .to)!
            
            UIView.animate(withDuration: 0.2, animations: {
                fromView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                toViewController.view.alpha = 1.0
            }) { completed in
                transitionContext.completeTransition(completed)
            }
        }
    }
    
}
