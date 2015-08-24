//
//  BPToolbar.m
//  Cakebrew
//
//  Created by Marek Hrusovsky on 16/08/15.
//	Copyright (c) 2014 Bruno Philipe. All rights reserved.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program.	If not, see <http://www.gnu.org/licenses/>.
//

#import "BPToolbar.h"
#import "BPAppDelegate.h"

static NSString *kToolbarIdentifier = @"toolbarIdentifier";

static NSString *kToolbarItemHomebrewUpdateIdentifier = @"toolbarItemHomebrewUpdate";
static NSString *kToolbarItemInformationIdentifier = @"toolbarItemInformation";
static NSString *kToolbarItemSearchIdentifier = @"toolbarItemSearch";
static NSString *kToolbarItemMultiActionIdentifier = @"toolbarItemMultiAction";


@interface BPToolbar() <NSTextFieldDelegate>

@property (assign) BPToolbarMode currentMode;
@property BOOL isFlat;

@end

@implementation BPToolbar

- (instancetype)initWithIdentifier:(NSString *)identifier
{
	self = [super initWithIdentifier:kToolbarIdentifier];
	if (self)
	{
		float OSXVersion = BPAppDelegateRef.OSXVersion;
		self.isFlat = OSXVersion >= 10.10;
		
		if (!self.isFlat)
		{
			[self setSizeMode:NSToolbarSizeModeSmall];
		}
		_currentMode = BPToolbarModeDefault;
		[self lockItems];
	}
	return self;
}

- (void)configureForMode:(BPToolbarMode)mode
{
	if (self.currentMode == mode) {
	  return;
	}
	self.currentMode = mode;
	NSToolbarItem *moreInfoItem = [self toolbarItemInformation];
	if (mode == BPToolbarModeTap ||
		mode == BPToolbarModeUntap ||
		mode == BPToolbarModeUpdateMany ||
		mode == BPToolbarModeDefault)
	{
		//will force toolbar to show empty nonclickable item
		[self reconfigureItem:moreInfoItem
					imageName:nil
						label:nil
					   action:nil];
  
	} else {
		[self reconfigureItem:moreInfoItem
					imageName:self.isFlat ? @"label_flat" : @"label.icns"
						label:NSLocalizedString(@"Toolbar_More_Information", nil)
					   action:@selector(showFormulaInfo:)];
	}
	
	
	NSToolbarItem *multiActionItem = [self toolbarItemMultiAction];
	switch (mode) {
		case BPToolbarModeDefault:
			[self reconfigureItem:multiActionItem
						imageName:nil
							label:nil
						   action:nil];
			break;
			
		case BPToolbarModeInstall:
			[self reconfigureItem:multiActionItem
						imageName:self.isFlat ? @"download_flat" : @"download.icns"
							label:NSLocalizedString(@"Toolbar_Install_Formula", nil)
						   action:@selector(installFormula:)];
			break;
			
		case BPToolbarModeUninstall:
			[self reconfigureItem:multiActionItem
						imageName:self.isFlat ? @"delete_flat" : @"delete.icns"
							label:NSLocalizedString(@"Toolbar_Uninstall_Formula", nil)
						   action:@selector(uninstallFormula:)];
			break;
			
		case BPToolbarModeTap:
			[self reconfigureItem:multiActionItem
						imageName:self.isFlat ? @"download_flat" : @"download.icns"
							label:NSLocalizedString(@"Toolbar_Tap_Repo", nil)
						   action:@selector(tapRepository:)];
			break;
			
		case BPToolbarModeUntap:
			[self reconfigureItem:multiActionItem
						imageName:self.isFlat ? @"delete_flat" : @"delete.icns"
							label:NSLocalizedString(@"Toolbar_Untap_Repo", nil)
						   action:@selector(untapRepository:)];
			break;
			
		case BPToolbarModeUpdateSingle:
			[self reconfigureItem:multiActionItem
						imageName:self.isFlat ? @"reload_flat" : @"reload.icns"
							label:NSLocalizedString(@"Toolbar_Update_Formula", nil)
						   action:@selector(upgradeSelectedFormulae:)];
			break;
			
		case BPToolbarModeUpdateMany:
			[self reconfigureItem:multiActionItem
						imageName:self.isFlat ? @"reload_flat" : @"reload.icns"
							label:NSLocalizedString(@"Toolbar_Update_Selected", nil)
						   action:@selector(upgradeSelectedFormulae:)];
			break;
			
		default:
			break;
	}
	[self validateVisibleItems];
}

- (void)setController:(id)controller
{
	if (_controller != controller) {
		_controller = controller;
		[self updateToolbarItemsWithTarget:controller];
	}
}



- (void)updateToolbarItemsWithTarget:(id)target
{
	NSDictionary *supportedItems = [self customToolbarItems];
	[supportedItems enumerateKeysAndObjectsUsingBlock:^(id key, NSToolbarItem *object, BOOL *stop) {
		[object setTarget:target];
	}];
}

- (void)lockItems
{
	[self updateToolbarItemsWithTarget:nil];
}

- (void)unlockItems
{
	[self updateToolbarItemsWithTarget:_controller];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSDictionary *supportedItems = [self customToolbarItems];
	if (![supportedItems objectForKey:itemIdentifier]){
		return nil;
	}
	return supportedItems[itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar{
	return @[kToolbarItemHomebrewUpdateIdentifier,
			 NSToolbarFlexibleSpaceItemIdentifier,
			 kToolbarItemMultiActionIdentifier,
			 kToolbarItemSearchIdentifier,
			 ];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar{
	NSArray *systemToolbarItems = [self systemToolbarItems];
	NSArray *customToolbarItems = @[kToolbarItemHomebrewUpdateIdentifier,
									kToolbarItemInformationIdentifier,
									kToolbarItemSearchIdentifier,
									kToolbarItemMultiActionIdentifier
									];
	return [systemToolbarItems arrayByAddingObjectsFromArray:customToolbarItems];
}

- (NSArray *)systemToolbarItems
{
	static NSArray *systemToolbarItems = nil;
	if (!systemToolbarItems) {
		systemToolbarItems =  @[
								NSToolbarSpaceItemIdentifier,
								NSToolbarFlexibleSpaceItemIdentifier,
								NSToolbarSeparatorItemIdentifier
								];
	}
	return systemToolbarItems;
}

- (NSDictionary *)customToolbarItems
{
	static NSDictionary *customToolbarItems = nil;
	if (!customToolbarItems) {
		customToolbarItems =  @{
								kToolbarItemHomebrewUpdateIdentifier : [self toolbarItemHomebrewUpdate],
								kToolbarItemInformationIdentifier : [self toolbarItemInformation],
								kToolbarItemSearchIdentifier : [self toolbarItemSearch],
								kToolbarItemMultiActionIdentifier : [self toolbarItemMultiAction]
								};
	}
	return customToolbarItems;
}

- (NSToolbarItem *)toolbarItemHomebrewUpdate
{
	static NSToolbarItem* toolbarItemHomebrewUpdate = nil;
	if (!toolbarItemHomebrewUpdate) {
		toolbarItemHomebrewUpdate = [self toolbarItemWithIdentifier:kToolbarItemHomebrewUpdateIdentifier
															   icon:self.isFlat ? @"globe_flat" : @"globe.icns"
															  label:NSLocalizedString(@"Toolbar_Homebrew_Update", nil)
															 action:@selector(updateHomebrew:)];
	}
	return toolbarItemHomebrewUpdate;
}

- (NSToolbarItem *)toolbarItemInformation
{
	static NSToolbarItem* toolbarItemInformation = nil;
	if (!toolbarItemInformation) {
		toolbarItemInformation = [self toolbarItemWithIdentifier:kToolbarItemInformationIdentifier
															icon:self.isFlat ? @"label_flat" : @"label.icns"
														   label:NSLocalizedString(@"Toolbar_More_Information", nil)
														  action:@selector(showFormulaInfo:)];
	}
	return toolbarItemInformation;
}


- (NSToolbarItem *)toolbarItemMultiAction
{
	static NSToolbarItem* toolbarItemMultiAction = nil;
	if (!toolbarItemMultiAction) {
		toolbarItemMultiAction = [self toolbarItemWithIdentifier:kToolbarItemMultiActionIdentifier
															icon:nil
														   label:nil
														  action:nil];
	}
	return toolbarItemMultiAction;
}



- (NSToolbarItem *)toolbarItemSearch {
	static NSToolbarItem* item = nil;
	if (!item) {
		item = [[NSToolbarItem alloc] initWithItemIdentifier:kToolbarItemSearchIdentifier];
		item.label = NSLocalizedString(@"Toolbar_Search", nil);
		item.paletteLabel = NSLocalizedString(@"Toolbar_Search", nil);
		item.action = @selector(performSearchWithString:);
		NSSearchField *searchField = [[NSSearchField alloc] initWithFrame:NSZeroRect];
		searchField.delegate = self;
		searchField.continuous = YES;
		[item setView:searchField];
	}
	return item;
}

- (NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)identifier
										icon:(NSString *)iconName
									   label:(NSString *)label
									  action:(SEL)action
{
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
	item.image = [NSImage imageNamed:iconName];
	item.label = label;
	item.paletteLabel = label;
	item.action = action;
	item.target = self.controller;
	item.autovalidates = YES;
	return item;
}

- (void)reconfigureItem:(NSToolbarItem *)item imageName:(NSString *)imageName label:(NSString *)label action:(SEL)action
{
	if (imageName)
	{
		item.image = [NSImage imageNamed:imageName];
	}
	else
	{
		item.image = [NSImage imageWithSize:NSMakeSize(32, 32) flipped:NO drawingHandler:nil];
	}
	
	item.label = label;
	item.action = action;
}

- (void)makeSearchFieldFirstResponder
{
	NSView *searchView = [[self toolbarItemSearch] view];
	[[searchView window] makeFirstResponder:searchView];
}

#pragma mark - NSTextField Delegate
- (void)controlTextDidChange:(NSNotification *)aNotification
{
	NSSearchField *field = (NSSearchField *)[aNotification object];
	[self.controller performSearchWithString:field.stringValue];
}

@end
