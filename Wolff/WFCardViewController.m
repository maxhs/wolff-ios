//
//  WFCardViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/20/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFCardViewController.h"
#import "WFAlert.h"
#import "WFAppDelegate.h"
#import <Stripe/Stripe.h>
#import "PTKView.h"

@interface WFCardViewController () <PTKViewDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    User *_currentUser;
    UIBarButtonItem *submitPaymentButton;
}
@property(weak, nonatomic) PTKView *paymentView;
@end

@implementation WFCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor clearColor]];
    
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    
    UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:self.view.frame];
    [backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
    [backgroundToolbar setTranslucent:YES];
    [self.view addSubview:backgroundToolbar];
    
    PTKView *view = [[PTKView alloc] initWithFrame:CGRectMake(111,54,290,55)];
    self.paymentView = view;
    self.paymentView.delegate = self;
    [self.view addSubview:self.paymentView];
    
    _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    submitPaymentButton = [[UIBarButtonItem alloc] initWithTitle:@"Submit" style:UIBarButtonItemStylePlain target:self action:@selector(submitPayment)];
    self.navigationItem.rightBarButtonItem = submitPaymentButton;
    submitPaymentButton.enabled = NO;

    
    self.title = @"Add Card";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.paymentView becomeFirstResponder];
}

- (void)paymentView:(PTKView *)view withCard:(PTKCard *)card isValid:(BOOL)valid {
    submitPaymentButton.enabled = valid;
}

- (void)submitPayment {
    STPCard *card = [[STPCard alloc] init];
    card.number = self.paymentView.card.number;
    card.expMonth = self.paymentView.card.expMonth;
    card.expYear = self.paymentView.card.expYear;
    card.cvc = self.paymentView.card.cvc;
    [ProgressHUD show:@"Adding your card..."];
    [Stripe createTokenWithCard:card completion:^(STPToken *token, NSError *error) {
        if (error) {
            //[self handleError:error];
            [WFAlert show:@"Sorry, but something went wrong while trying to add your billing information.\n\nPlease try again soon." withTime:3.7f];
        } else {
            //[self submitPayment:token];
            NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
            [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
            [parameters setObject:token.tokenId forKey:@"token"];
            [parameters setObject:card.last4 forKey:@"last4"];
            if (card.cardId.length){
                [parameters setObject:card.cardId forKey:@"card_id"];
            }
            [parameters setObject:@(card.expMonth) forKey:@"exp_month"];
            [parameters setObject:@(card.expYear) forKey:@"exp_year"];
            
            [manager POST:@"cards" parameters:@{@"card":parameters,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Success creating a user card: %@",responseObject);
                if ([responseObject objectForKey:@"card"]){
                    Card *userCard = [Card MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    [userCard populateFromDictionary:[responseObject objectForKey:@"card"]];
                    [_currentUser addCard:userCard];
                    [ProgressHUD dismiss];
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        if (self.cardDelegate && [self.cardDelegate respondsToSelector:@selector(addedCardWithId:)]){
                            [self.cardDelegate addedCardWithId:userCard.identifier];
                        }
                        [self.navigationController popViewControllerAnimated:YES];
                    }];
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [ProgressHUD dismiss];
                [WFAlert show:@"Sorry, but something went wrong while trying to add your billing information.\n\nPlease try again soon." withTime:3.7f];
                [self.navigationController popViewControllerAnimated:YES];
                NSLog(@"Failed to create a user card: %@",error.description);
            }];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
