//
//  WFLightTableCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFLightTableCell.h"
#import "Constants.h"

@implementation WFLightTableCell

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
    UIView *selectedView = [[UIView alloc] initWithFrame:self.frame];
    [selectedView setBackgroundColor:kDarkTableViewCellSelectionColor];
    self.selectedBackgroundView = selectedView;
    
    [_label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansSemibold] size:0]];
    [_label setTextColor:[UIColor whiteColor]];
    [_label setText:@""];
    [_pieceCountLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSans] size:0]];
    [_tableLabel setTextColor:[UIColor whiteColor]];

    [_deleteButton setImage:[UIImage imageNamed:@"whiteTrash"] forState:UIControlStateNormal];
    [_deleteButton setBackgroundColor:[UIColor redColor]];
    [_deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_deleteButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    
    [_editButton setImage:[UIImage imageNamed:@"settings"] forState:UIControlStateNormal];
    [_editButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_editButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    
    [_leaveButton setImage:[UIImage imageNamed:@"dismissWhite"] forState:UIControlStateNormal];
    _leaveButton.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    _leaveButton.titleLabel.layer.shadowRadius = 1.4f;
    _leaveButton.titleLabel.layer.shadowOpacity = .23f;
    _leaveButton.titleLabel.layer.shadowOffset = CGSizeMake(.23f, .23f);
    
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

- (void)configureForTable:(LightTable *)table {
    //set up the action button
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && [table includesOwnerId:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        [_editButton setHidden:NO];
        [_deleteButton setHidden:NO];
        [_leaveButton setHidden:YES];
        //readjust the scrollView depending on if the user should see the edit button
        [_scrollView setContentSize:CGSizeMake(kSidebarWidth+200, self.contentView.frame.size.height)];
    } else {
        
        [_editButton setHidden:YES];
        [_deleteButton setHidden:YES];
        [_leaveButton setHidden:NO];
        
        //readjust the scrollView depending on if the user should see the edit button
        [_scrollView setContentSize:CGSizeMake(kSidebarWidth+100, self.contentView.frame.size.height)];
    }
    
    //set up the title
    if (table.name.length){
        [_tableLabel setText:table.name];
        [_tableLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansItalic] size:0]];
    } else {
        [_tableLabel setText:@"No name..."];
        [_tableLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLightItalic] size:0]];
    }
    NSString *pieceCount = table.photos.count == 1 ? @"1 slide" : [NSString stringWithFormat:@"%lu slides",(unsigned long)table.photos.count];
    [_pieceCountLabel setText:pieceCount];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat contentOffsetX = scrollView.contentOffset.x;
    _editButton.transform = CGAffineTransformMakeTranslation(-contentOffsetX, 0);
    _deleteButton.transform = CGAffineTransformMakeTranslation(-contentOffsetX, 0);
    _leaveButton.transform = CGAffineTransformMakeTranslation(-contentOffsetX, 0);
}

@end
