/* ChatViewController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "ChatsListView.h"
#import "PhoneMainView.h"

@implementation ChatsListView

#pragma mark - Lifecycle Functions

- (id)init {
	return [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle mainBundle]];
}

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textReceivedEvent:)
												 name:kLinphoneMessageReceived
											   object:nil];
	[self setEditing:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneMessageReceived object:nil];
}

#pragma mark - Event Functions

- (void)textReceivedEvent:(NSNotification *)notif {
	[_tableController loadData];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:self.class
															  statusBar:StatusBarView.class
																 tabBar:TabBarView.class
															 fullscreen:false
														  landscapeMode:LinphoneManager.runningOnIpad
														   portraitMode:true];
	}
	return compositeDescription;
}

- (UICompositeViewDescription *)compositeViewDescription {
	return self.class.compositeViewDescription;
}

#pragma mark - Action Functions

- (void)startChatRoom {
	// Push ChatRoom
	LinphoneChatRoom *room =
		linphone_core_get_chat_room_from_uri([LinphoneManager getLc], [_addressField.text UTF8String]);
	if (room != nil) {
		ChatConversationView *view = VIEW(ChatConversationView);
		[PhoneMainView.instance changeCurrentView:view.compositeViewDescription push:TRUE];
		[view setChatRoom:room];
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid address", nil)
														message:@"Please specify the entire SIP address for the chat"
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											  otherButtonTitles:nil];
		[alert show];
	}
	_addressField.text = @"";
}

- (IBAction)onAddClick:(id)event {
	if (_addressField.text.length == 0) { // if no address is manually set, lauch address book
		[ContactSelection setSelectionMode:ContactSelectionModeMessage];
		[ContactSelection setAddAddress:nil];
		[ContactSelection setSipFilter:[LinphoneManager instance].contactFilter];
		[ContactSelection enableEmailFilter:FALSE];
		[ContactSelection setNameOrEmailFilter:nil];
		[PhoneMainView.instance changeCurrentView:ContactsListView.compositeViewDescription push:TRUE];
	} else {
		[self startChatRoom];
	}
}

- (void)setEditing:(BOOL)editing {
	[_tableController setEditing:editing animated:TRUE];
	_toggleSelectionButton.hidden = _backButton.hidden = _deleteButton.hidden = !editing;
	_addButton.hidden = _editButton.hidden = editing;
}

- (IBAction)onEditToggle:(id)event {
	[self setEditing:!_tableController.isEditing];
}

- (IBAction)onSelectionToggle:(id)sender {
}

#pragma mark - UITextFieldDelegate Functions

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[_addressField resignFirstResponder];
	if (_addressField.text.length > 0)
		[self startChatRoom];
	return YES;
}
@end
