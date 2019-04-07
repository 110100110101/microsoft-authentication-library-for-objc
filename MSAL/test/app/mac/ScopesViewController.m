//
//  ScopesViewController.m
//  MSALMacTestApp
//
//  Created by Rohit Narula on 4/5/19.
//  Copyright © 2019 Microsoft. All rights reserved.
//

#import "ScopesViewController.h"
#import "MSALTestAppSettings.h"

@interface ScopesViewController ()
@property NSMutableArray *scopesList;
@property (weak) IBOutlet NSTableView *scopesView;
@property (weak) IBOutlet NSTextField *scopesText;

@end

@implementation ScopesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.scopesView.delegate = self;
    self.scopesView.dataSource = self;
    [self.scopesView setAllowsMultipleSelection: YES];
    self.scopesList = [[NSMutableArray alloc] init];
    
    [[MSALTestAppSettings availableScopes] enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idex, BOOL *stop){
        [self.scopesList addObject:obj];
    }];
    
    [self.scopesView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [self.scopesList count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *scope = [self.scopesList objectAtIndex:row];
    NSString *identifier = [tableColumn identifier];
    if ([identifier isEqualToString:@"ScopesCell"])
    {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
        [cellView.textField setStringValue:scope];
        return cellView;
    }
    return nil;
}

- (IBAction)insertNewRow:(id)sender
{
    NSString *scope = [self.scopesText stringValue];
    
    if (scope.length > 0  && ![self.scopesList containsObject:scope])
    {
        NSInteger selectedRow = [self.scopesView selectedRow];
        selectedRow++;
        [self.scopesList insertObject:scope atIndex:selectedRow];
        [self.scopesView beginUpdates];
        [self.scopesView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:selectedRow] withAnimation:NSTableViewAnimationEffectGap];
        [self.scopesView scrollRowToVisible:selectedRow];
        [self.scopesView endUpdates];
    }
}

- (IBAction)deleteSelectedRows:(id)sender
{
    NSIndexSet *indexes = [self.scopesView selectedRowIndexes];
    [self.scopesList removeObjectsAtIndexes:indexes];
    [self.scopesView removeRowsAtIndexes:indexes withAnimation:NSTableViewAnimationSlideDown];
}

- (IBAction)done:(id)sender
{
    NSIndexSet *indexes = [self.scopesView selectedRowIndexes];
    NSMutableArray *selectedScopes = [[NSMutableArray alloc] init];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        [selectedScopes addObject:[self.scopesList objectAtIndex:idx]];
    }];
    
    [self.delegate setScopes:selectedScopes];
    [self dismissViewController:self];
}


@end
