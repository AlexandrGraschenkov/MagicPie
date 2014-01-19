//
//  Example3Controller.m
//  MagicPie
//
//  Created by Alexander on 18.01.14.
//  Copyright (c) 2014 Alexandr Corporation. All rights reserved.
//

#import "Example3Controller.h"
@import AVFoundation;
@import MediaPlayer;
#import "Example3PieView.h"

@interface Example3Controller ()
{
    AVAudioPlayer* player;
    NSArray* symbols;
    NSTimer* changeSymbolTimer;
}
@property (nonatomic, weak) IBOutlet Example3PieView* pieView;
@property (nonatomic, weak) IBOutlet UIButton* playPauseButton;
@property (nonatomic, weak) IBOutlet UILabel* symbolLabel;
@end

@implementation Example3Controller
@synthesize playPauseButton, pieView, symbolLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    symbols = @[@"🇷🇺", @"😁", @"😈", @"📣", @"👻", @"🚨", @"💣"];
    [self initAudioPlayer];
    if(player)
        pieView.player = player;
}

- (void)initAudioPlayer
{
    NSURL *audioFileURL = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"m4a"];
    NSError *error;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL error:&error];
    if (!error) {
        [player setNumberOfLoops:-1];
        [player setMeteringEnabled:YES];
        playPauseButton.enabled = YES;
    } else {
        NSLog(@"%@", [error localizedDescription]);
        playPauseButton.enabled = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [player prepareToPlay];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [player stop];
    [changeSymbolTimer invalidate];
    changeSymbolTimer = nil;
}

#pragma mark - Actions
- (IBAction)backPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)customDrawingSwitchChanged:(UISwitch*)sender
{
    pieView.enableCustomDrawing = sender.isOn;
}

- (IBAction)playPausePressed:(UIButton*)sender
{
    if(player.isPlaying){
        [sender setTitle:@"Play" forState:UIControlStateNormal];
        [sender setBackgroundColor:[UIColor colorWithRed:0.491 green:0.100 blue:0.087 alpha:1.000]];
        [player pause];
        symbolLabel.text = nil;
        [changeSymbolTimer invalidate];
        changeSymbolTimer = nil;
    } else {
        [sender setTitle:@"Pause" forState:UIControlStateNormal];
        [sender setBackgroundColor:[UIColor colorWithRed:0.147 green:0.491 blue:0.167 alpha:1.000]];
        [player play];
        changeSymbolTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(changeSymbol:) userInfo:nil repeats:YES];
        [self changeSymbol:changeSymbolTimer];
    }
}

#pragma mark -
- (void)changeSymbol:(NSTimer*)timer
{
    symbolLabel.text = symbols[arc4random() % symbols.count];
}

@end
