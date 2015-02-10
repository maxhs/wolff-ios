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
    [self.textLabel setText:@""];
    
    [_label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansSemibold] size:0]];
    [_label setTextColor:[UIColor whiteColor]];
    [_label setText:@""];
    
    [_tableLabel setTextColor:[UIColor whiteColor]];
    [_pieceCountLabel setTextColor:[UIColor colorWithWhite:1 alpha:.33]];
    
    UIView *selectedView = [[UIView alloc] initWithFrame:self.frame];
    [selectedView setBackgroundColor:kDarkTableViewCellSelectionColor];
    self.selectedBackgroundView = selectedView;

    [_actionButton setBackgroundColor:[UIColor redColor]];
    [_actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_actionButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    
    [_editButton setBackgroundColor:kElectricBlue];
    [_editButton setTitle:@"Edit" forState:UIControlStateNormal];
    [_editButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_editButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    
    [_scrollView setUserInteractionEnabled:NO];
    [self.contentView addGestureRecognizer:_scrollView.panGestureRecognizer];
    _scrollView.delegate = self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self setBackgroundColor:[UIColor clearColor]];
    [_pieceCountLabel setText:@""];
    [_tableLabel setText:@""];
    [_label setText:@""];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureForTable:(Table *)table {
    _lightTable = table;
    //set up the action button
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && [_lightTable.owner.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        [_actionButton setTitle:@"Delete" forState:UIControlStateNormal];
        [_actionButton setBackgroundColor:[UIColor redColor]];
        [_actionButton addTarget:self action:@selector(deleteLightTable) forControlEvents:UIControlEventTouchUpInside];
        
        [_editButton setHidden:NO];
        [_editButton addTarget:self action:@selector(editLightTable) forControlEvents:UIControlEventTouchUpInside];
        
        //readjust the scrollView depending on if the user should see the edit button
        [_scrollView setContentSize:CGSizeMake(kSidebarWidth+200, self.contentView.frame.size.height)];
    } else {
        [_actionButton setTitle:@"Remove" forState:UIControlStateNormal];
        [_actionButton setBackgroundColor:kSaffronColor];
        [_actionButton addTarget:self action:@selector(leaveLightTable) forControlEvents:UIControlEventTouchUpInside];
        _actionButton.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        _actionButton.titleLabel.layer.shadowRadius = 1.4f;
        _actionButton.titleLabel.layer.shadowOpacity = .23f;
        _actionButton.titleLabel.layer.shadowOffset = CGSizeMake(.23f, .23f);
        [_editButton setHidden:YES];
        
        //readjust the scrollView depending on if the user should see the edit button
        [_scrollView setContentSize:CGSizeMake(kSidebarWidth+100, self.contentView.frame.size.height)];
        [_actionButton setFrame:_editButton.frame];
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
    _editButton.transform = CGAffineTransformMakeTranslation(-contentOffsetX, 0);
    _actionButton.transform = CGAffineTransformMakeTranslation(-contentOffsetX, 0);
}

- (void)leaveLightTable {
    if (self.delegate && [self.delegate respondsToSelector:@selector(leaveLightTable:)]){
        [self.delegate leaveLightTable:_lightTable.identifier];
    }
}

- (void)deleteLightTable {
    if (self.delegate && [self.delegate respondsToSelector:@selector(deleteLightTable:)]){
        [self.delegate deleteLightTable:_lightTable.identifier];
    }
}

- (void)editLightTable {
    if (self.delegate && [self.delegate respondsToSelector:@selector(editLightTable:)]){
        [self.delegate editLightTable:_lightTable.identifier];
    }
}

@end
