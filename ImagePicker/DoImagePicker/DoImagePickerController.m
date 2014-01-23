//
//  DoImagePickerController.m
//  ImagePicker
//
//  Created by Seungbo Cho on 2014. 1. 23..
//  Copyright (c) 2014년 Seungbo Cho. All rights reserved.
//

#import "DoImagePickerController.h"
#import "AssetHelper.h"

#import "DoAlbumCell.h"
#import "DoPhotoCell.h"

@implementation DoImagePickerController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initBottomMenu];
    [self initSideButtons];
    
    UINib *nib = [UINib nibWithNibName:@"DoPhotoCell" bundle:nil];
    [_cvPhotoList registerNib:nib forCellWithReuseIdentifier:@"DoPhotoCell"];
    
    _tvAlbumList.frame = CGRectMake(0, _vBottomMenu.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    _tvAlbumList.alpha = 0.0;
    
    [ASSETHELPER getGroupList:^(NSArray *aGroups) {
        
        [_tvAlbumList reloadData];
        [_tvAlbumList selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
        
        [_btSelectAlbum setTitle:[ASSETHELPER getGroupInfo:0][@"name"] forState:UIControlStateNormal];
        [self showPhotosInGroup:0];
        
        if (aGroups.count == 1)
            _btSelectAlbum.enabled = NO;
        
        // calculate tableview's height
        _tvAlbumList.frame = CGRectMake(_tvAlbumList.frame.origin.x, _tvAlbumList.frame.origin.y, _tvAlbumList.frame.size.width, MIN(aGroups.count * 50, 300) + 3);

    }];

    ASSETHELPER.bReverse = YES;
	
	if (_nMaxCount > 1)
	{
		_dSelect = [[NSMutableDictionary alloc] initWithCapacity:_nMaxCount];
		
		// init gesture
		UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
		[self.view addGestureRecognizer:pan];
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
	[ASSETHELPER clearData];
}

#pragma mark - for bottom menu
- (void)initBottomMenu
{
    _vBottomMenu.backgroundColor = DO_MENU_BACK_COLOR;
    [_btSelectAlbum setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_btSelectAlbum setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
    
    _ivLine1.frame = CGRectMake(_ivLine1.frame.origin.x, _ivLine1.frame.origin.y, 0.5, _ivLine1.frame.size.height);
    _ivLine2.frame = CGRectMake(_ivLine2.frame.origin.x, _ivLine2.frame.origin.y, 0.5, _ivLine2.frame.size.height);
    
    if (_nMaxCount <= 1)
    {
        // hide ok button
        _btOK.hidden = YES;
        _ivLine1.hidden = YES;
        
        CGRect rect = _btSelectAlbum.frame;
        rect.size.width = rect.size.width + 60;
        _btSelectAlbum.frame = rect;
    }
}

- (IBAction)onSelectPhoto:(id)sender
{
	NSMutableArray *aResult = [[NSMutableArray alloc] initWithCapacity:_dSelect.count];
	NSArray *aKeys = _dSelect.allKeys;
	
	for (int i = 0; i < _dSelect.count; i++)
		[aResult addObject:[ASSETHELPER getImageAtIndex:[aKeys[i] integerValue] type:ASSET_PHOTO_SCREEN_SIZE]];
		
    [_delegate didSelectPhotosFromDoImagePickerController:aResult];
}

- (IBAction)onCancel:(id)sender
{
    [_delegate didCancelDoImagePickerController];
}

- (IBAction)onSelectAlbum:(id)sender
{
    [UIView animateWithDuration:0.2 animations:^(void) {
        
        _tvAlbumList.frame = CGRectMake(0, _vBottomMenu.frame.origin.y - _tvAlbumList.frame.size.height,
                                        _tvAlbumList.frame.size.width, _tvAlbumList.frame.size.height);
        _tvAlbumList.alpha = 1.0;


    } completion:^(BOOL finished) {

        [UIView animateWithDuration:0.1 animations:^(void) {

            _tvAlbumList.frame = CGRectMake(0, _vBottomMenu.frame.origin.y - _tvAlbumList.frame.size.height + 3,
                                            _tvAlbumList.frame.size.width, _tvAlbumList.frame.size.height);
            
        }];
        
    }];
}

#pragma mark - for side buttons
- (void)initSideButtons
{
    _btUp.backgroundColor = DO_SIDE_BUTTON_COLOR;
    _btDown.backgroundColor = DO_SIDE_BUTTON_COLOR;
}

- (IBAction)onUp:(id)sender
{
    [_cvPhotoList scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
}

- (IBAction)onDown:(id)sender
{
    [_cvPhotoList scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[ASSETHELPER getPhotoCountOfCurrentGroup] - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
}

#pragma mark - UITableViewDelegate for selecting album
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [ASSETHELPER getGroupCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DoAlbumCell *cell = (DoAlbumCell*)[tableView dequeueReusableCellWithIdentifier:@"DoAlbumCell"];
    
    if (cell == nil)
    {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"DoAlbumCell" owner:nil options:nil] lastObject];
    }

    NSDictionary *d = [ASSETHELPER getGroupInfo:indexPath.row];
    cell.lbAlbumName.text   = d[@"name"];
    cell.lbCount.text       = [NSString stringWithFormat:@"%@", d[@"count"]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self showPhotosInGroup:indexPath.row];
    [_btSelectAlbum setTitle:[ASSETHELPER getGroupInfo:indexPath.row][@"name"] forState:UIControlStateNormal];

    [UIView animateWithDuration:0.2 animations:^(void) {

        _tvAlbumList.frame = CGRectMake(0, _vBottomMenu.frame.origin.y, _tvAlbumList.frame.size.width, _tvAlbumList.frame.size.height);
        _tvAlbumList.alpha = 0.0;

    }];
}

#pragma mark - UICollectionViewDelegates for photos
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [ASSETHELPER getPhotoCountOfCurrentGroup];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DoPhotoCell *cell = (DoPhotoCell *)[_cvPhotoList dequeueReusableCellWithReuseIdentifier:@"DoPhotoCell" forIndexPath:indexPath];

    cell.ivPhoto.image = [ASSETHELPER getImageAtIndex:indexPath.row type:ASSET_PHOTO_THUMBNAIL];

	if (_dSelect[@(indexPath.row)] == nil)
		[cell setSelectMode:NO];
    else
		[cell setSelectMode:YES];
	
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_nMaxCount <= 1)
    {
        [_delegate didSelectPhotosFromDoImagePickerController:@[[ASSETHELPER getImageAtIndex:indexPath.row type:ASSET_PHOTO_SCREEN_SIZE]]];
    }
	else
	{
		DoPhotoCell *cell = (DoPhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];

		if ((_dSelect[@(indexPath.row)] == nil) && (_nMaxCount > _dSelect.count))
		{
			// select
			_dSelect[@(indexPath.row)] = @"Y";
			[cell setSelectMode:YES];
		}
		else
		{
			// unselect
			[_dSelect removeObjectForKey:@(indexPath.row)];
			[cell setSelectMode:NO];
		}

	}
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSLog(@"scrollview offset : %@", NSStringFromCGPoint(scrollView.contentOffset));
    
    if (scrollView == _cvPhotoList)
    {
        [UIView animateWithDuration:0.2 animations:^(void) {
            if (scrollView.contentOffset.y <= 50)
                _btUp.alpha = 0.0;
            else
                _btUp.alpha = 1.0;
            
            if (scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height)
                _btDown.alpha = 0.0;
            else
                _btDown.alpha = 1.0;
        }];
    }
}

// for multiple selection with panning
- (void)handleGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    double fX = [gestureRecognizer locationInView:_cvPhotoList].x;
    double fY = [gestureRecognizer locationInView:_cvPhotoList].y;
	
    for (UICollectionViewCell *cell in _cvPhotoList.visibleCells)
	{
        float fSX = cell.frame.origin.x;
        float fEX = cell.frame.origin.x + cell.frame.size.width;
        float fSY = cell.frame.origin.y;
        float fEY = cell.frame.origin.y + cell.frame.size.height;
        
        if (fX >= fSX && fX <= fEX && fY >= fSY && fY <= fEY)
        {
            NSIndexPath *indexPath = [_cvPhotoList indexPathForCell:cell];
            
            if (_lastAccessed != indexPath)
            {
				[self collectionView:_cvPhotoList didSelectItemAtIndexPath:indexPath];
            }
            
            _lastAccessed = indexPath;
        }
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        _lastAccessed = nil;
        _cvPhotoList.scrollEnabled = YES;
    }
}

#pragma mark - for photos
- (void)showPhotosInGroup:(NSInteger)nIndex
{
    [ASSETHELPER getPhotoListOfGroupByIndex:nIndex result:^(NSArray *aPhotos) {
        
        [_cvPhotoList reloadData];
		if (aPhotos.count > 0)
		{
			[_cvPhotoList scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        }

        _btUp.alpha = 0.0;

		if (_cvPhotoList.contentSize.height < _cvPhotoList.frame.size.height)
			_btDown.alpha = 0.0;
    }];
}

#pragma mark - Others
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end