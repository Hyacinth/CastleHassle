//
//  HUD.m
//  Rev3
//
//  Created by Bryce Redd on 11/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "HUD.h"
#import "Battlefield.h"
#import "HUDMenu.h"
#import "HUDItem.h"
#import "HUDActionController.h"
#import "HUDSelectedMenu.h"
#import "ButtonItem.h"
#import "BuildItem.h"
#import "PurchaseItem.h"
#import "PieceList.h"
#import "GoldItem.h"
#import "SettingsFromGame.h"

@implementation HUD

@synthesize selectedMenu, countDownTimer, settingsView, inFocus, mainMenu, buildMenu, buildNextMenu;

-(id) initWithManagers:(NSDictionary*)mans {
	
	if( (self=[super init]) ) {
		managers = mans;
		menuIsHidden = NO;
		splashMsg = nil;
		lastSecond = 0;
		
		[[HUDActionController instance] setHud:self];
		tabMgr = [managers objectForKey:@"hud"];
		tabUpSprite = spriteWithRect(@"hud.png", CGRectMake(184, 58, 112, 22));
		tabUpSprite.position = CGPointMake(480.0/2.0, 320.0-HUD_HEIGHT-(22.0/2.0));
		
		tabDownSprite = spriteWithRect(@"hud.png", CGRectMake(184, 81, 112, 22));
		tabDownSprite.position = CGPointMake(480.0/2.0, 320.0-(22.0/2.0));
		[tabDownSprite setVisible:NO];
		
		tabSprite = spriteWithRect(@"hud.png", CGRectMake(0, 0, 480, HUD_HEIGHT));
		tabSprite.position = CGPointMake(480.0/2.0, 320.0-(HUD_HEIGHT/2.0));
		[tabSprite setVisible:YES];
		
		[tabSprite setOpacity:200.0f];
		
		[tabMgr addChild:tabUpSprite];
		[tabMgr addChild:tabDownSprite];
		[tabMgr addChild:tabSprite];
		
		[self initBuildMenu];
		[self initBuildNextMenu];
		[self initMainMenu];
		[self showMainMenu];
		
		selectedMenu = nil;
		
		// init gold box
		gold = [[GoldItem alloc] init];
		gold.leftBound = 360;
		gold.rightBound = gold.leftBound+100;

		gold.img = spriteWithRect(@"hud.png", CGRectMake(0, 0, 20, 20));
		gold.img.position = ccp(0, 320-HUD_HEIGHT-15);
		[self addChild:gold.img];
		[gold postInit];
		[gold show];
		
		
	}
	return self;
}

-(void) initMainMenu {
	self.countDownTimer = [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:48.0];
	self.countDownTimer.position = ccp(240.0, 180.0);
	self.countDownTimer.color = ccRED;
	[[Battlefield instance] addChild:self.countDownTimer z:ANIMATION_Z_INDEX];
	
	self.mainMenu = [[[HUDMenu alloc] initWithManagers:managers] autorelease];
	
	[mainMenu addButtonItemWithImageName:@"stdButtons"
								   imageBox:CGRectMake(0, 77, 104, 37) 
							  swingImageBox:CGRectMake(0, 0, 0, 0)
								  selector:@selector(showBuildMenu) 
									 title:@"Build"]; 

	/*[mainMenu addButtonItemWithImageName:@"stdButtons"
								  imageBox:CGRectMake(0, 77, 104, 37) 
							 swingImageBox:CGRectMake(0, 0, 0, 0)
								  selector:@selector(save) 
									 title:@"Save"];
	
	[mainMenu addButtonItemWithImageName:@"stdButtons"
								  imageBox:CGRectMake(0, 77, 104, 37) 
							 swingImageBox:CGRectMake(0, 0, 0, 0)
								  selector:@selector(clear) 
									 title:@"Clear"];
	
	//[mainMenu addGoldStatusWithLeft:160.0];
	
	[mainMenu addButtonItemWithImageName:@"stdButtons"
								  imageBox:CGRectMake(0, 77, 104, 37) 
							 swingImageBox:CGRectMake(0, 0, 0, 0)
								  selector:@selector(load) 
									 title:@"Load"];*/
	
	ButtonItem * settingButton = [mainMenu addButtonItemWithImageName:@"stdButtons"
															   imageBox:CGRectMake(0, 77, 104, 37) 
														  swingImageBox:CGRectMake(0, 0, 0, 0)
															   selector:@selector(showSettings) 
																  title:@"Menu"]; 
	

	
	settingButton.leftBound = 480-ICON_SPACING-settingButton.img.textureRect.size.width;
	settingButton.rightBound = 480-ICON_SPACING;
	
	
	[mainMenu hideAll];
}

-(void) initSelectedMenu:(Piece*)p {
	
	selectedMenu = [[HUDSelectedMenu alloc] initWithManagers:managers];
	
	NSString* mgrName = [NSStringFromClass([p class]) lowercaseString];
	
	if([p isKindOfClass:[Weapon class]]) {
		
		Weapon* w = (Weapon*)p;
		[selectedMenu addStatusItemWithImageName:mgrName 
										  imageBox:w.currentSprite.textureRect 
									 swingImageBox:w.swingSprite.textureRect
											 piece:w];
		
		
		
	} else {
		[selectedMenu addStatusItemWithImageName:mgrName 
										  imageBox:p.currentSprite.textureRect 
									 swingImageBox:CGRectMake(0, 0, 0, 0) 
											 piece:p];	
	}
	
	[selectedMenu addPurchaseItemWithImageName:@"stdButtons"
										imageBox:CGRectMake(0, 77, 104, 37) 
								   swingImageBox:CGRectMake(0, 0, 0, 0)
										selector:@selector(repairPiece) 
										   title:@"Repair" 
										   piece:p];
	
	if([p isKindOfClass:[Weapon class]]) {
		
		[selectedMenu addPurchaseItemWithImageName:@"stdButtons"
											imageBox:CGRectMake(0, 0, 145, 37) 
									   swingImageBox:CGRectMake(0, 0, 0, 0)
											selector:@selector(upgradePiece) 
											   title:@"Upgrade" 
											   piece:p];
	}
	
	
	/*[selectedMenu addButtonItemWithImageName:@"stdButtons" 
									  imageBox:CGRectMake(187, 76, 40, 39) 
								 swingImageBox:CGRectMake(0,0,0,0)
									  selector:@selector(infoClicked) 
										 title:@""];*/
	
	[self addBackButtonToMenu:(HUDMenu*)selectedMenu];
	
	[selectedMenu hideAll];
}

-(void) initBuildNextMenu {
	
	self.buildNextMenu = [[[HUDMenu alloc] initWithManagers:managers] autorelease];
	
	[buildNextMenu addButtonItemWithImageName:@"stdButtons"
								   imageBox:CGRectMake(105, 78, 38, 37) 
							  swingImageBox:CGRectMake(0, 0, 0, 0)
								   selector:@selector(previousConstructionItems) 
									  title:@""];
	
	[buildNextMenu addBuildItemWithImageName:@"arch"
								  imageBox:CGRectMake(0, 0, 60, 30) 
							 swingImageBox:CGRectMake(0, 0, 0, 0)
									 class:[Arch class]
									 price:ARCH_BUY_PRICE]; 
	
	[buildNextMenu addBuildItemWithImageName:@"wedge"
									  imageBox:CGRectMake(0, 0, 30, 30) 
								 swingImageBox:CGRectMake(0, 0, 0, 0)
										 class:[Wedge class]
										 price:WEDGE_BUY_PRICE]; 
	
	[buildNextMenu addBuildItemWithImageName:@"balcony"
								  imageBox:CGRectMake(0, 0, 30, 30) 
							 swingImageBox:CGRectMake(0, 0, 0, 0)
									 class:[Balcony class]
									 price:BALCONY_BUY_PRICE]; 
	
	[buildNextMenu addBuildItemWithImageName:@"wall"
									  imageBox:CGRectMake(0, 0, 30, 30) 
								 swingImageBox:CGRectMake(0, 0, 0, 0)
										 class:[Wall class]
										 price:WALL_BUY_PRICE];
	
	[buildNextMenu addBuildItemWithImageName:@"merlin"
									  imageBox:CGRectMake(0, 0, 30, 30) 
								 swingImageBox:CGRectMake(0, 0, 0, 0)
										 class:[Merlin class]
										 price:MERLIN_BUY_PRICE];	
	
		
	ButtonItem* leftBtn = [buildNextMenu addButtonItemWithImageName:@"stdButtons"
								   imageBox:CGRectMake(146, 78, 38, 37) 
							  swingImageBox:CGRectMake(0, 0, 0, 0)
								   selector:@selector(nextConstructionItems) 
									  title:@""];
	[leftBtn.img setOpacity:100.0f];
	
	[self addBackButtonToMenu:buildNextMenu];
	
	[buildNextMenu hideAll];
}

-(void) initBuildMenu {
	self.buildMenu = [[[HUDMenu alloc] initWithManagers:managers] autorelease];
	
	ButtonItem* leftBtn = [buildMenu addButtonItemWithImageName:@"stdButtons"
								   imageBox:CGRectMake(105, 78, 38, 37) 
							  swingImageBox:CGRectMake(0, 0, 0, 0)
								   selector:@selector(previousConstructionItems) 
									  title:@""];
	[leftBtn.img setOpacity:100.0f];
	
	[buildMenu addBuildItemWithImageName:@"tower"
								  imageBox:CGRectMake(0, 0, 30, 30) 
							 swingImageBox:CGRectMake(0, 0, 0, 0)
									 class:[Tower class] 
									 price:TOWER_BUY_PRICE]; 
	
	[buildMenu addBuildItemWithImageName:@"turret"
								  imageBox:CGRectMake(0, 0, 36, 30) 
							 swingImageBox:CGRectMake(0, 0, 0, 0)
									 class:[Turret class] 
									 price:TURRET_BUY_PRICE]; 
	
	[buildMenu addBuildItemWithImageName:@"cannon"
									  imageBox:CGRectMake(0,26,30,14)
								 swingImageBox:CGRectMake(0,0,45,11) 
										 class:[Cannon class]
										 price:CANNON_BUY_PRICE];
	
	[buildMenu addBuildItemWithImageName:@"catapult"
									  imageBox:CGRectMake(3, 6, 23, 22)
								 swingImageBox:CGRectMake(0, 0, 35, 5) 
										 class:[Catapult class]
										 price:CATAPULT_BUY_PRICE];
	
	[buildMenu addBuildItemWithImageName:@"top"
								  imageBox:CGRectMake(0, 0, 34, 27)
							 swingImageBox:CGRectMake(0, 0, 0, 0)
									 class:[Top class] 
									 price:TOP_BUY_PRICE]; 
	
	[buildMenu addButtonItemWithImageName:@"stdButtons"
								   imageBox:CGRectMake(146, 78, 38, 37) 
							  swingImageBox:CGRectMake(0, 0, 0, 0)
								   selector:@selector(nextConstructionItems) 
									  title:@""];
	
	[self addBackButtonToMenu:buildMenu];
	
	[buildMenu hideAll];
}

-(void) addBackButtonToMenu:(HUDMenu*)menu {
	
	HUDItem * backButton = [menu addButtonItemWithImageName:@"stdButtons"
													 imageBox:CGRectMake(125, 39, 49, 35) 
												swingImageBox:CGRectMake(0, 0, 0, 0)
													 selector:@selector(showMainMenu) 
														title:@""]; 
	
	backButton.leftBound = 480-BACK_BUTTON_SPACING_FROM_RIGHT-(backButton.img.textureRect.size.width/2);
	backButton.rightBound = 480-BACK_BUTTON_SPACING_FROM_RIGHT+(backButton.img.textureRect.size.width/2);
}

-(void) showBuildMenu {
	[self showMenu:buildMenu];
}

-(void) showBuildNextMenu {
	[self showMenu:buildNextMenu];
}

-(void) showMainMenu {
	[self showMenu:mainMenu];
}

-(void) showSelectedMenu:(Piece *)piece {
	
	if(piece && !menuIsHidden) {
		// construct a selectedmenu
		HUDMenu * oldSelectedMenu = selectedMenu;
		
		[self initSelectedMenu:piece];
		[self showMenu:selectedMenu];

		if(oldSelectedMenu) 
			[oldSelectedMenu release];
            
	} else {
		if(inFocus && inFocus == selectedMenu)
			[self showMainMenu];
	}
	
}

-(void) showMenu:(HUDMenu*)menu {
	[self hideMenu];
	[menu showAll];
	inFocus = menu;
}

-(void) hideMenu {
	if(inFocus != nil)
		[inFocus hideAll]; 
	
	inFocus = nil;
}

-(void) collapseMenu {
	menuIsHidden = YES;
	gold.img.position = ccpAdd(gold.img.position, ccp(0.0, HUD_HEIGHT));
	gold.amount.position = ccpAdd(gold.amount.position, ccp(0.0, HUD_HEIGHT));
	[tabDownSprite setVisible:YES];
	[tabUpSprite setVisible:NO];
	[tabSprite setVisible:NO];
	[self hideMenu];
}

-(void) expandMenu {
	menuIsHidden = NO;
	gold.img.position = ccpAdd(gold.img.position, ccp(0.0, -HUD_HEIGHT));
	gold.amount.position = ccpAdd(gold.amount.position, ccp(0.0, -HUD_HEIGHT));
	[tabDownSprite setVisible:NO];
	[tabUpSprite setVisible:YES];
	[tabSprite setVisible:YES];
	[self showMainMenu];
}

-(void) showSettings {

	[[Battlefield instance] resetScreenToX:160.0];
	
	// add settings layer
	self.settingsView = [[[SettingsFromGame alloc] init] autorelease];
	[[Battlefield instance] addChild:settingsView z:10];
	settingsView.position = ccp(0,0);
}

-(void) hideSettings {
	[[Battlefield instance] removeChild:settingsView cleanup:YES];
	self.settingsView = nil;
}

-(void) moveAllObjects:(CGPoint)p {
	tabUpSprite.position = CGPointMake(tabUpSprite.position.x - p.x, tabUpSprite.position.y);
	tabDownSprite.position = CGPointMake(tabDownSprite.position.x - p.x, tabDownSprite.position.y);
	tabSprite.position = CGPointMake(tabSprite.position.x - p.x, tabSprite.position.y);

	if(splashMsg != nil) {
		splashMsg.position = CGPointMake(splashMsg.position.x - p.x, splashMsg.position.y);
	}

	if (settingsView != nil) {
		settingsView.position = ccp(settingsView.position.x - p.x, settingsView.position.y);
	}
	
	if(self.countDownTimer.visible) {
		self.countDownTimer.position = ccp(self.countDownTimer.position.x - p.x, self.countDownTimer.position.y);
	}
	
	if(inFocus != nil) {
		[inFocus moveAllObjects:p];
	}
	
	[gold move:p];
	
}

-(BOOL) handleInitialTouch:(CGPoint)p {
	
	if(settingsView)
		return YES;
	
	if(CGRectContainsPoint([self tabRect], p)) {
		if(menuIsHidden)
			[self expandMenu];
		else
			[self collapseMenu];
		
		return YES;
	}
		
	if(inFocus != nil)
		return [inFocus handleInitialTouch:p];
	
	return NO;
}

-(BOOL) handleTouchDrag:(CGPoint)p {
	if(settingsView != nil)
		return YES;
	
	if(inFocus != nil)
		return [inFocus handleTouchDrag:p];
	
	return NO;
}

-(BOOL) handleEndTouch:(CGPoint)p {
	if(settingsView != nil)
		return YES;
	
	if(inFocus != nil)
		return [inFocus handleEndTouch:p];
	
	return NO;
}

-(void) showMessage:(NSString*)message {
	
	if(splashMsg != nil) {
		[self removeMessage];
	}
	
	splashMsg = [CCLabelTTF labelWithString:message fontName:@"Arial" fontSize:24.0];
	splashMsg.color = ccRED;
	[splashMsg setPosition:CGPointMake(tabDownSprite.position.x, 320-HUD_HEIGHT-50)];
	
	 // add some animation
	id labelAction1 = [CCScaleTo actionWithDuration:0.05 scale:1.1];
	id labelAction2 = [CCScaleTo actionWithDuration:0.1 scale:1.0];
	id labelAction3 = [CCScaleTo actionWithDuration:1.5 scale:1.0];
	
	id seq3 = [CCSequence actionOne:labelAction3 two:[CCCallFunc actionWithTarget:self selector:@selector(removeMessage)]];
	id seq2 = [CCSequence actionOne:labelAction2 two:seq3];
	id seq1 = [CCSequence actionOne:labelAction1 two:seq2];
	 
	[splashMsg runAction:seq1];
	 
	[[Battlefield instance] addChild:splashMsg z:ANIMATION_Z_INDEX];
	splashMsg.visible = YES;
}

-(void) removeMessage {
	[[Battlefield instance] removeChild:splashMsg cleanup:YES];
	splashMsg = nil;
}

-(void) setCountdownTimer:(float)timeRemaining {
	
	if(timeRemaining<0.0 && self.countDownTimer.visible) {
		[self showMessage:@"Open fire!"];
		[self.countDownTimer setVisible:NO];
	}
	
	if(timeRemaining>0.0 && !self.countDownTimer.visible) {
		self.countDownTimer.position = ccp(tabSprite.position.x, self.countDownTimer.position.y);
		[self.countDownTimer setVisible:YES];
	}
	
	if(lastSecond != (int)timeRemaining) {
		[self.countDownTimer setString:[NSString stringWithFormat:@"%.00f", timeRemaining]];
		lastSecond = (int)timeRemaining;
	}
}

-(BOOL) handleDragExit:(CGPoint)p {
	
	if(inFocus != nil)
		return [inFocus handleDragExit:p];
	
	return NO;
}

-(CGRect) hudRect {
	return CGRectMake(0,320-HUD_HEIGHT,480,HUD_HEIGHT);
}

-(CGRect) tabRect {
	if(menuIsHidden)
		return CGRectMake((480-tabUpSprite.textureRect.size.width)/2.0, 
						  320-tabUpSprite.textureRect.size.height, 
						  tabUpSprite.textureRect.size.width, 
						  tabUpSprite.textureRect.size.height);
	else
		return CGRectMake((480-tabUpSprite.textureRect.size.width)/2.0, 
						  320-HUD_HEIGHT-tabUpSprite.textureRect.size.height, 
						  tabUpSprite.textureRect.size.width, 
						  tabUpSprite.textureRect.size.height);
}

-(void) dealloc {
	
    [gold release];
	[buildMenu release];
    [buildNextMenu release];
	[mainMenu release];
	[selectedMenu release];
	
    self.countDownTimer = nil;
	
	[super dealloc];
}

@end