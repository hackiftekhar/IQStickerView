//
//  ZDStickerView.h
//
//  Created by Seonghyun Kim on 5/29/13.
//  Copyright (c) 2013 scipi. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol IQStickerViewDelegate;

@interface IQStickerView : UIView<UIGestureRecognizerDelegate>
{
    UIImageView *resizeView;
    UIImageView *rotateView;
    UIImageView *closeView;

    BOOL _isShowingEditingHandles;
}

@property (assign, nonatomic) UIView *contentView;
@property (weak, nonatomic) id <IQStickerViewDelegate> delegate;

@property(nonatomic, assign) BOOL showContentShadow;    //Default is YES.
@property(nonatomic, assign) BOOL enableClose;  // default is YES. if set to NO, user can't delete the view
@property(nonatomic, assign) BOOL enableResize;  // default is YES. if set to NO, user can't Resize the view
@property(nonatomic, assign) BOOL enableRotate;  // default is YES. if set to NO, user can't Rotate the view

//Give call's to refresh. If SuperView is UIScrollView. And it changes it's zoom scale.
-(void)refresh;

- (void)hideEditingHandles;
- (void)showEditingHandles;

@end

@protocol IQStickerViewDelegate <NSObject>
@optional
- (void)stickerViewDidBeginEditing:(IQStickerView *)sticker;
- (void)stickerViewDidChangeEditing:(IQStickerView *)sticker;
- (void)stickerViewDidEndEditing:(IQStickerView *)sticker;

- (void)stickerViewDidClose:(IQStickerView *)sticker;

- (void)stickerViewDidShowEditingHandles:(IQStickerView *)sticker;
- (void)stickerViewDidHideEditingHandles:(IQStickerView *)sticker;
@end


