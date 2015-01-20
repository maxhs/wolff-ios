//
//  WFMainTableCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFMainTableCell.h"
#import "Constants.h"

@interface WFMainTableCell (){
    Table *_lightTable;
    
}

@end
@implementation WFMainTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    UIView *clearFrame = [[UIView alloc] initWithFrame:self.frame];
    [clearFrame setBackgroundColor:[UIColor clearColor]];
    self.backgroundView = clearFrame;
    
    [_label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansSemibold] size:0]];
    [_label setTextColor:[UIColor whiteColor]];
    [_label setText:@""];
    
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansItalic] size:0]];
    [self.textLabel setTextColor:[UIColor whiteColor]];
    [self.textLabel setText:@""];
    [self.textLabel setTextAlignment:NSTextAlignmentCenter];

    [_tableLabel setTextColor:[UIColor whiteColor]];
    [_pieceCountLabel setTextColor:[UIColor colorWithWhite:1 alpha:.33]];
    
    UIView *selectedView = [[UIView alloc] initWithFrame:self.frame];
    [selectedView setBackgroundColor:kDarkTableViewCellSelectionColor];
    self.selectedBackgroundView = selectedView;

    [_actionButton setBackgroundColor:[UIColor redColor]];
    [_actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_actionButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    
    //ensure that the scrollView can actually scroll
    [_scrollView setContentSize:CGSizeMake(kSidebarWidth+100, self.contentView.frame.size.height)];
    [_scrollView setUserInteractionEnabled:NO];
    [self.contentView addGestureRecognizer:_scrollView.panGestureRecognizer];
    _scrollView.delegate = self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_pieceCountLabel setText:@""];
    [_tableLabel setText:@""];
    [_label setText:@""];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureForTable:(Table *)table {
    _lightTable = table;
    //set up the actio button
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && [_lightTable.owner.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        [_actionButton setTitle:@"Delete" forState:UIControlStateNormal];
        [_actionButton setBackgroundColor:[UIColor redColor]];
        [_actionButton addTarget:self action:@selector(deleteLightTable) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [_actionButton setTitle:@"Remove" forState:UIControlStateNormal];
        [_actionButton setBackgroundColor:kSaffronColor];
        [_actionButton addTarget:self action:@selector(leaveLightTable) forControlEvents:UIControlEventTouchUpInside];
        _actionButton.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        _actionButton.titleLabel.layer.shadowRadius = 2.3f;
        _actionButton.titleLabel.layer.shadowOpacity = .5f;
        _actionButton.titleLabel.layer.shadowOffset = CGSizeMake(.3f, .3f);
    }
    
    //set up the title
    if (_lightTable.name.length){
        [_tableLabel setText:_lightTable.name];
        [_tableLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansItalic] size:0]];
    } else {
        [_tableLabel setText:@"No name..."];
        [_tableLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLightItalic] size:0]];
    }
    NSString *pieceCount = _lightTable.photos.count == 1 ? @"1 slide" : [NSString stringWithFormat:@"%lu slides",(unsigned long)_lightTable.photos.count];
    [_pieceCountLabel setText:pieceCount];
    [_pieceCountLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansItalic] size:0]];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat contentOffsetX = scrollView.contentOffset.x;
    _actionButton.transform = CGAffineTransformMakeTranslation(-contentOffsetX, 0);
}

- (void)leaveLightTable {
    if (self.delegate && [self.delegate respondsToSelector:@selector(leaveLightTable:)]){
        [self.delegate leaveLightTable:_lightTable];
    }
}

- (void)deleteLightTable {
    if (self.delegate && [self.delegate respondsToSelector:@selector(deleteLightTable:)]){
        [self.delegate deleteLightTable:_lightTable];
    }
}

@end
